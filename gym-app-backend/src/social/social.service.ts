import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseService } from '../supabase/supabase.service';
import {
  CreateCommentDto,
  CreatePostDto,
  ShareWorkoutDto,
} from './dto/social.dto';

/** Soft caps to stop feed/comment spam without Redis. */
const RATE_LIMITS = {
  workoutShare: { max: 6, windowMs: 60 * 60 * 1000 }, // 6 / hour
  staffPost: { max: 10, windowMs: 60 * 60 * 1000 }, // 10 / hour
  comment: { max: 30, windowMs: 60 * 60 * 1000 }, // 30 / hour
} as const;

// Shared post select shape used in list and get queries
const POST_SELECT = {
  id: true,
  gymId: true,
  userId: true,
  workoutSessionId: true,
  content: true,
  imageUrl: true,
  imagePath: true,
  achievementType: true,
  achievementId: true,
  isFlagged: true,
  isDeleted: true,
  createdAt: true,
  updatedAt: true,
  user: {
    select: {
      id: true,
      displayName: true,
    },
  },
  workoutSession: {
    select: {
      id: true,
      startedAt: true,
      endedAt: true,
      notes: true,
      sets: {
        where: { deletedAt: null },
        select: {
          reps: true,
          weightKg: true,
          exercise: { select: { name: true } },
        },
      },
    },
  },
  likes: {
    select: { userId: true },
  },
  comments: {
    where: { isDeleted: false },
    select: { id: true },
  },
  certification: {
    select: {
      createdAt: true,
      coach: { select: { displayName: true } },
    },
  },
};

const MODERATION_POST_SELECT = {
  id: true,
  gymId: true,
  userId: true,
  content: true,
  imageUrl: true,
  imagePath: true,
  achievementType: true,
  isFlagged: true,
  isDeleted: true,
  createdAt: true,
  user: {
    select: {
      id: true,
      displayName: true,
    },
  },
  likes: {
    select: { userId: true },
  },
  comments: {
    where: { isDeleted: false },
    select: { id: true },
  },
  flags: {
    select: { userId: true },
  },
  certification: {
    select: {
      createdAt: true,
      coach: { select: { displayName: true } },
    },
  },
};

@Injectable()
export class SocialService {
  constructor(
    private prisma: PrismaService,
    private supabase: SupabaseService,
  ) {}

  // ─── Feed ───────────────────────────────────────────────────────────────────

  async getFeed(
    gymId: string,
    requestingUserId: string,
    limit: number,
    offset: number,
  ) {
    const posts = await this.prisma.post.findMany({
      where: {
        gymId,
        isDeleted: false,
        // Standalone PR auto-posts were retired — they flooded the feed.
        // Keep shared workouts, staff announcements, and other types.
        OR: [{ achievementType: null }, { achievementType: { not: 'pr' } }],
        // Exclude posts this user has flagged
        NOT: {
          flags: {
            some: { userId: requestingUserId },
          },
        },
      },
      select: POST_SELECT,
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const staffRoles = await this.getStaffRoles(gymId);
    const signedUrls = await this.supabase.createPostImageSignedUrls(
      posts
        .map((post) => post.imagePath)
        .filter((path): path is string => Boolean(path)),
    );
    return Promise.all(
      posts.map((post) =>
        this.formatPost(
          post,
          requestingUserId,
          staffRoles.get(post.userId),
          signedUrls,
        ),
      ),
    );
  }

  async getMemberPosts(
    gymId: string,
    memberId: string,
    requestingUserId: string,
    limit: number,
    offset: number,
  ) {
    const posts = await this.prisma.post.findMany({
      where: {
        gymId,
        userId: memberId,
        isDeleted: false,
        OR: [{ achievementType: null }, { achievementType: { not: 'pr' } }],
        NOT: { flags: { some: { userId: requestingUserId } } },
      },
      select: POST_SELECT,
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
    const staffRole = await this.getStaffRole(gymId, memberId);
    const signedUrls = await this.supabase.createPostImageSignedUrls(
      posts
        .map((post) => post.imagePath)
        .filter((path): path is string => Boolean(path)),
    );
    return Promise.all(
      posts.map((post) =>
        this.formatPost(post, requestingUserId, staffRole, signedUrls),
      ),
    );
  }

  // ─── Staff: Create announcement post ───────────────────────────────────────

  async createStaffPost(
    userId: string,
    gymId: string,
    dto: CreatePostDto,
  ) {
    await this.assertPostRateLimit(
      userId,
      gymId,
      RATE_LIMITS.staffPost,
      'Too many posts. Try again later.',
    );

    const post = await this.prisma.post.create({
      data: {
        id: crypto.randomUUID(),
        gymId,
        userId,
        content: dto.content,
        imageUrl: dto.imageUrl ?? null,
        achievementType: dto.type, // 'announcement' | 'class_update' | 'reminder'
      },
      select: POST_SELECT,
    });
    return this.formatPost(post, userId, await this.getStaffRole(gymId, userId));
  }

  // ─── Member workout sharing ───────────────────────────────────────────────

  async shareWorkout(
    userId: string,
    gymId: string,
    sessionId: string,
    dto: ShareWorkoutDto,
  ) {
    const session = await this.prisma.workoutSession.findFirst({
      where: {
        id: sessionId,
        gymId,
        endedAt: { not: null },
        deletedAt: null,
        OR: [
          { userId },
          { participants: { some: { userId } } },
        ],
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: { select: { name: true } } },
          orderBy: { createdAt: 'asc' },
        },
        participants: {
          include: {
            user: { select: { id: true, displayName: true, email: true } },
          },
        },
      },
    });

    if (!session) {
      throw new NotFoundException('Completed workout not found');
    }

    const existing = await this.prisma.post.findFirst({
      where: { workoutSessionId: sessionId, isDeleted: false },
      select: POST_SELECT,
    });
    if (existing) {
      return this.formatPost(
        existing,
        userId,
        await this.getStaffRole(gymId, userId),
      );
    }

    await this.assertPostRateLimit(
      userId,
      gymId,
      RATE_LIMITS.workoutShare,
      'Too many workout shares. Try again later.',
    );

    let imagePath: string | null = null;
    if (dto.imagePath?.trim()) {
      const member = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { authProviderId: true },
      });
      const expectedPrefix = member?.authProviderId
        ? `${member.authProviderId}/`
        : null;
      if (!expectedPrefix || !dto.imagePath.startsWith(expectedPrefix)) {
        throw new BadRequestException('Invalid workout photo path');
      }
      imagePath = dto.imagePath;
    }

    const summary = this.workoutSummary(session);
    const prs = await this.prisma.userAchievement.findMany({
      where: {
        userId,
        gymId,
        achievementType: 'pr',
        earnedAt: {
          gte: session.startedAt,
          lte: session.endedAt ?? new Date(),
        },
      },
      include: { exercise: { select: { name: true } } },
      orderBy: { earnedAt: 'asc' },
    });
    const prCount = prs.length;

    const buddyNames = (session.participants ?? [])
      .filter((p) => p.userId !== userId)
      .map((p) => p.user.displayName || p.user.email?.split('@')[0] || 'buddy')
      .filter(Boolean);
    const withSuffix =
      buddyNames.length > 0
        ? ` with ${buddyNames.map((n) => `@${n}`).join(', ')}`
        : '';

    const content =
      dto.content?.trim() ||
      (prCount > 0
        ? `Workout complete — ${summary.exerciseCount} exercises, ${summary.totalSets} sets, ${prCount} PR${prCount === 1 ? '' : 's'}${withSuffix}.`
        : `Workout complete — ${summary.exerciseCount} exercises, ${summary.totalSets} sets${withSuffix}.`);

    const post = await this.prisma.post.create({
      data: {
        id: crypto.randomUUID(),
        gymId,
        userId,
        workoutSessionId: sessionId,
        content,
        imagePath,
        achievementType: 'workout_complete',
      },
      select: POST_SELECT,
    });

    return this.formatPost(
      post,
      userId,
      await this.getStaffRole(gymId, userId),
    );
  }

  // ─── Likes ──────────────────────────────────────────────────────────────────

  async toggleLike(userId: string, gymId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
    });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.prisma.postLike.findFirst({
      where: { postId, userId },
    });

    if (existing) {
      await this.prisma.postLike.delete({ where: { id: existing.id } });
      return { liked: false };
    }

    await this.prisma.postLike.create({
      data: { id: crypto.randomUUID(), postId, userId },
    });
    return { liked: true };
  }

  // ─── Flagging ───────────────────────────────────────────────────────────────

  async flagPost(userId: string, gymId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
    });
    if (!post) throw new NotFoundException('Post not found');

    // Record the flag — upsert so flagging twice is idempotent
    await this.prisma.postFlag.upsert({
      where: { postId_userId: { postId, userId } },
      create: { id: crypto.randomUUID(), postId, userId },
      update: {},
    });

    // Mark the post as flagged so it appears in the moderation queue
    await this.prisma.post.update({
      where: { id: postId },
      data: { isFlagged: true },
    });

    return { flagged: true };
  }

  // ─── Comments ───────────────────────────────────────────────────────────────

  async getComments(gymId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
    });
    if (!post) throw new NotFoundException('Post not found');

    return this.prisma.postComment.findMany({
      where: { postId, isDeleted: false },
      select: {
        id: true,
        content: true,
        createdAt: true,
        user: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createComment(
    userId: string,
    gymId: string,
    postId: string,
    dto: CreateCommentDto,
  ) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
    });
    if (!post) throw new NotFoundException('Post not found');

    await this.assertCommentRateLimit(userId, RATE_LIMITS.comment);

    return this.prisma.postComment.create({
      data: {
        id: crypto.randomUUID(),
        postId,
        userId,
        content: dto.content,
      },
      select: {
        id: true,
        content: true,
        createdAt: true,
        user: { select: { id: true, displayName: true } },
      },
    });
  }

  async deleteComment(userId: string, gymId: string, commentId: string) {
    const comment = await this.prisma.postComment.findFirst({
      where: {
        id: commentId,
        isDeleted: false,
        post: { gymId, isDeleted: false },
      },
    });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.userId !== userId) throw new ForbiddenException();

    await this.prisma.postComment.update({
      where: { id: commentId },
      data: { isDeleted: true },
    });
    return { deleted: true };
  }

  // ─── Coach certification ──────────────────────────────────────────────────

  async certifyWorkout(
    coachUserId: string,
    gymId: string,
    postId: string,
  ) {
    const post = await this.prisma.post.findFirst({
      where: {
        id: postId,
        gymId,
        isDeleted: false,
        achievementType: 'workout_complete',
        workoutSessionId: { not: null },
        userId: { not: coachUserId },
      },
      select: { id: true },
    });
    if (!post) {
      throw new NotFoundException(
        'Only another member’s completed workout can be certified',
      );
    }

    const existing = await this.prisma.coachCertification.findUnique({
      where: { postId },
      select: {
        createdAt: true,
        coach: { select: { displayName: true } },
      },
    });
    if (existing) {
      return {
        certified: true,
        coachName: existing.coach.displayName ?? 'Coach',
        certifiedAt: existing.createdAt,
      };
    }

    const certification = await this.prisma.coachCertification.create({
      data: {
        id: crypto.randomUUID(),
        postId,
        coachUserId,
        gymId,
      },
      select: {
        createdAt: true,
        coach: { select: { displayName: true } },
      },
    });
    return {
      certified: true,
      coachName: certification.coach.displayName ?? 'Coach',
      certifiedAt: certification.createdAt,
    };
  }

  async listCertifyQueue(gymId: string, coachUserId: string, limit = 30) {
    const posts = await this.prisma.post.findMany({
      where: {
        gymId,
        isDeleted: false,
        achievementType: 'workout_complete',
        workoutSessionId: { not: null },
        userId: { not: coachUserId },
        certification: null,
      },
      select: {
        id: true,
        content: true,
        createdAt: true,
        achievementType: true,
        user: { select: { id: true, displayName: true, email: true } },
        likes: { select: { id: true } },
        comments: { where: { isDeleted: false }, select: { id: true } },
        workoutSession: {
          include: {
            sets: {
              where: { deletedAt: null },
              include: { exercise: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return posts.map((post) => ({
      id: post.id,
      content: post.content,
      createdAt: post.createdAt,
      likeCount: post.likes.length,
      commentCount: post.comments.length,
      achievementType: post.achievementType,
      workoutSummary: post.workoutSession
        ? this.workoutSummary(post.workoutSession)
        : null,
      authorName: post.user.displayName || post.user.email || 'Member',
      authorId: post.user.id,
    }));
  }

  async listFlaggedPosts(gymId: string) {
    const posts = await this.prisma.post.findMany({
      where: {
        gymId,
        isDeleted: false,
        isFlagged: true,
      },
      select: MODERATION_POST_SELECT,
      orderBy: { createdAt: 'desc' },
    });

    const staffRoles = await this.getStaffRoles(gymId);
    return Promise.all(
      posts.map((post) =>
        this.formatModerationPost(post, staffRoles.get(post.userId)),
      ),
    );
  }

  async listRecentPostsForStaff(gymId: string, limit = 20) {
    const take = Math.min(Math.max(Math.trunc(limit) || 20, 1), 50);
    const posts = await this.prisma.post.findMany({
      where: { gymId, isDeleted: false },
      select: MODERATION_POST_SELECT,
      orderBy: { createdAt: 'desc' },
      take,
    });

    const staffRoles = await this.getStaffRoles(gymId);
    return Promise.all(
      posts.map((post) =>
        this.formatModerationPost(post, staffRoles.get(post.userId)),
      ),
    );
  }

  async dismissFlaggedPost(gymId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
      select: { id: true },
    });
    if (!post) throw new NotFoundException('Post not found');

    return this.prisma.post.update({
      where: { id: postId },
      data: { isFlagged: false },
      select: { id: true, isFlagged: true },
    });
  }

  async softDeletePostAsStaff(gymId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, gymId, isDeleted: false },
      select: { id: true },
    });
    if (!post) throw new NotFoundException('Post not found');

    return this.prisma.post.update({
      where: { id: postId },
      data: { isDeleted: true },
      select: { id: true, isDeleted: true },
    });
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────

  private async getStaffRole(gymId: string, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { authProviderId: true },
    });
    if (!user?.authProviderId) return null;
    const staff = await this.prisma.gymStaff.findFirst({
      where: { gymId, authProviderId: user.authProviderId },
      select: { role: true },
    });
    return staff?.role ?? null;
  }

  private async getStaffRoles(gymId: string) {
    const staff = await this.prisma.gymStaff.findMany({
      where: { gymId, authProviderId: { not: null } },
      select: { authProviderId: true, role: true },
    });
    const authIds = staff
      .map((row) => row.authProviderId)
      .filter((id): id is string => id !== null);
    if (authIds.length === 0) return new Map<string, string>();

    const users = await this.prisma.user.findMany({
      where: { authProviderId: { in: authIds } },
      select: { id: true, authProviderId: true },
    });
    const rolesByAuthId = new Map(
      staff
        .filter((row): row is { authProviderId: string; role: string } =>
          row.authProviderId !== null,
        )
        .map((row) => [row.authProviderId, row.role]),
    );
    return new Map(
      users.map((user) => [
        user.id,
        rolesByAuthId.get(user.authProviderId!) ?? 'staff',
      ]),
    );
  }

  private workoutSummary(session: any) {
    const sets = session.sets ?? [];
    const exerciseNames = [
      ...new Set(
        sets
          .map((set: any) => set.exercise?.name)
          .filter((name: string | undefined): name is string => Boolean(name)),
      ),
    ];
    const volumeKg = sets.reduce(
      (total: number, set: any) =>
        total + Number(set.weightKg ?? 0) * Number(set.reps ?? 0),
      0,
    );
    const durationSeconds =
      session.endedAt && session.startedAt
        ? Math.max(
            0,
            Math.round(
              (session.endedAt.getTime() - session.startedAt.getTime()) / 1000,
            ),
          )
        : 0;

    return {
      durationSeconds,
      totalSets: sets.length,
      exerciseCount: exerciseNames.length,
      volumeKg: Math.round(volumeKg * 100) / 100,
      exerciseNames,
    };
  }

  private async assertPostRateLimit(
    userId: string,
    gymId: string,
    limit: { max: number; windowMs: number },
    message: string,
  ) {
    const since = new Date(Date.now() - limit.windowMs);
    const recentCount = await this.prisma.post.count({
      where: {
        userId,
        gymId,
        createdAt: { gte: since },
        isDeleted: false,
      },
    });
    if (recentCount >= limit.max) {
      throw new HttpException(message, HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  private async assertCommentRateLimit(
    userId: string,
    limit: { max: number; windowMs: number },
  ) {
    const since = new Date(Date.now() - limit.windowMs);
    const recentCount = await this.prisma.postComment.count({
      where: {
        userId,
        createdAt: { gte: since },
        isDeleted: false,
      },
    });
    if (recentCount >= limit.max) {
      throw new HttpException(
        'Too many comments. Try again later.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async formatPost(
    post: any,
    requestingUserId: string,
    staffRole?: string | null,
    signedUrlByPath?: Map<string, string | null>,
  ) {
    let imageUrl = post.imageUrl;
    if (post.imagePath) {
      if (signedUrlByPath?.has(post.imagePath)) {
        imageUrl = signedUrlByPath.get(post.imagePath) ?? null;
      } else {
        imageUrl = await this.supabase.createPostImageSignedUrl(post.imagePath);
      }
    }
    return {
      id: post.id,
      gymId: post.gymId,
      authorId: post.userId,
      authorName: post.user?.displayName ?? 'Member',
      content: post.content ?? '',
      imageUrl,
      imagePath: post.imagePath ?? null,
      achievementType: post.achievementType,
      workoutSessionId: post.workoutSessionId,
      workoutSummary: post.workoutSession
        ? this.workoutSummary(post.workoutSession)
        : null,
      authorIsStaff: Boolean(staffRole),
      authorStaffRole: staffRole,
      isOwnPost: post.userId === requestingUserId,
      coachCertification: post.certification
        ? {
            coachName: post.certification.coach.displayName ?? 'Coach',
            certifiedAt: post.certification.createdAt,
          }
        : null,
      likeCount: post.likes?.length ?? 0,
      commentCount: post.comments?.length ?? 0,
      isLiked: post.likes?.some((l: any) => l.userId === requestingUserId) ?? false,
      isFlagged: post.isFlagged,
      createdAt: post.createdAt,
    };
  }

  private async formatModerationPost(post: any, staffRole?: string | null) {
    const imageUrl = post.imagePath
      ? await this.supabase.createPostImageSignedUrl(post.imagePath)
      : post.imageUrl;

    return {
      id: post.id,
      gymId: post.gymId,
      userId: post.userId,
      content: post.content ?? '',
      imageUrl,
      achievementType: post.achievementType,
      isFlagged: post.isFlagged,
      isDeleted: post.isDeleted,
      createdAt: post.createdAt,
      authorName: post.user?.displayName ?? 'Member',
      authorRole: staffRole ?? null,
      likeCount: post.likes?.length ?? 0,
      commentCount: post.comments?.length ?? 0,
      flagCount: post.flags?.length ?? 0,
      coachCertification: post.certification
        ? {
            coachName: post.certification.coach.displayName ?? 'Coach',
            certifiedAt: post.certification.createdAt,
          }
        : null,
    };
  }
}
