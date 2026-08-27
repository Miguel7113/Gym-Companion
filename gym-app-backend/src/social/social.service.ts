import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePostDto, CreateCommentDto } from './dto/social.dto';

// ─── Body-part → default image URL map ────────────────────────────────────────
// Used when auto-generating achievement posts so the image is contextual
// to the muscle group the PR was set on.
const BODY_PART_IMAGES: Record<string, string> = {
  chest:
    'https://images.unsplash.com/photo-1534368786749-b63e05c92717?w=800&q=80',
  back:
    'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=80',
  'upper arms':
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
  'lower arms':
    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
  shoulders:
    'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=80',
  'upper legs':
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
  'lower legs':
    'https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=800&q=80',
  waist:
    'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80',
  'lower back':
    'https://images.unsplash.com/photo-1566241832378-917a0f30db2c?w=800&q=80',
  cardio:
    'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=80',
  neck:
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
  default:
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
};

function imageForBodyParts(bodyParts: string[]): string {
  for (const part of bodyParts) {
    if (BODY_PART_IMAGES[part.toLowerCase()]) {
      return BODY_PART_IMAGES[part.toLowerCase()];
    }
  }
  return BODY_PART_IMAGES['default'];
}

// Shared post select shape used in list and get queries
const POST_SELECT = {
  id: true,
  gymId: true,
  userId: true,
  content: true,
  imageUrl: true,
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
  likes: {
    select: { userId: true },
  },
  comments: {
    where: { isDeleted: false },
    select: { id: true },
  },
};

@Injectable()
export class SocialService {
  constructor(private prisma: PrismaService) {}

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

    return posts.map((p) => this.formatPost(p, requestingUserId));
  }

  // ─── Staff: Create announcement post ───────────────────────────────────────

  async createStaffPost(
    userId: string,
    gymId: string,
    dto: CreatePostDto,
  ) {
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
    return this.formatPost(post, userId);
  }

  // ─── Auto-generate achievement post (called from WorkoutsService) ──────────

  async createAchievementPost(params: {
    userId: string;
    gymId: string;
    achievementId: string;
    exerciseName: string;
    value: string; // e.g. "100kg × 5 reps"
    bodyParts: string[];
  }) {
    const content =
      `New PR — ${params.value} on ${params.exerciseName}! 💪`;

    const imageUrl = imageForBodyParts(params.bodyParts);

    return this.prisma.post.create({
      data: {
        id: crypto.randomUUID(),
        gymId: params.gymId,
        userId: params.userId,
        content,
        imageUrl,
        achievementType: 'pr',
        achievementId: params.achievementId,
      },
    });
  }

  // ─── Likes ──────────────────────────────────────────────────────────────────

  async toggleLike(userId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
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

  async flagPost(userId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
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

  async getComments(postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
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
    postId: string,
    dto: CreateCommentDto,
  ) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
    });
    if (!post) throw new NotFoundException('Post not found');

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

  async deleteComment(userId: string, commentId: string) {
    const comment = await this.prisma.postComment.findFirst({
      where: { id: commentId, isDeleted: false },
    });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.userId !== userId) throw new ForbiddenException();

    await this.prisma.postComment.update({
      where: { id: commentId },
      data: { isDeleted: true },
    });
    return { deleted: true };
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────

  private formatPost(post: any, requestingUserId: string) {
    return {
      id: post.id,
      gymId: post.gymId,
      authorId: post.userId,
      authorName: post.user?.displayName ?? 'Member',
      content: post.content,
      imageUrl: post.imageUrl,
      achievementType: post.achievementType,
      likeCount: post.likes?.length ?? 0,
      commentCount: post.comments?.length ?? 0,
      isLiked: post.likes?.some((l: any) => l.userId === requestingUserId) ?? false,
      isFlagged: post.isFlagged,
      createdAt: post.createdAt,
    };
  }
}
