import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SocialService } from '../social/social.service';
import { UpdateMemberDto } from './dto/update-member.dto';

@Injectable()
export class MembersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly social: SocialService,
  ) {}

  /**
   * Peer directory for the gym floor (excludes viewer + coach/admin staff users).
   * Includes buddyStatus and isTrainingNow for Home / See all.
   */
  async listDirectory(viewerId: string, gymId: string, q?: string) {
    const staff = await this.prisma.gymStaff.findMany({
      where: {
        gymId,
        role: { in: ['coach', 'admin'] },
        authProviderId: { not: null },
      },
      select: { authProviderId: true },
    });
    const staffAuthIds = staff
      .map((s) => s.authProviderId)
      .filter((id): id is string => !!id);

    const query = (q ?? '').trim();
    const users = await this.prisma.user.findMany({
      where: {
        gymId,
        id: { not: viewerId },
        ...(staffAuthIds.length
          ? { NOT: { authProviderId: { in: staffAuthIds } } }
          : {}),
        ...(query
          ? { displayName: { contains: query, mode: 'insensitive' } }
          : {}),
      },
      select: { id: true, displayName: true },
      take: 60,
      orderBy: { displayName: 'asc' },
    });

    if (users.length === 0) return [];

    const userIds = users.map((u) => u.id);
    const [activeSessions, buddyLinks] = await Promise.all([
      this.prisma.workoutSession.findMany({
        where: {
          gymId,
          endedAt: null,
          deletedAt: null,
          OR: [
            { userId: { in: userIds } },
            { participants: { some: { userId: { in: userIds } } } },
          ],
        },
        select: {
          userId: true,
          participants: { select: { userId: true } },
        },
      }),
      this.prisma.gymBuddyLink.findMany({
        where: {
          gymId,
          status: { in: ['pending', 'active'] },
          OR: [{ userAId: viewerId }, { userBId: viewerId }],
        },
        select: {
          id: true,
          status: true,
          requestedByUserId: true,
          userAId: true,
          userBId: true,
        },
      }),
    ]);

    const trainingIds = new Set<string>();
    for (const session of activeSessions) {
      trainingIds.add(session.userId);
      for (const p of session.participants) trainingIds.add(p.userId);
    }

    const buddyByOther = new Map<
      string,
      { buddyLinkId: string; buddyStatus: string }
    >();
    for (const link of buddyLinks) {
      const otherId = link.userAId === viewerId ? link.userBId : link.userAId;
      let buddyStatus = 'none';
      if (link.status === 'active') {
        buddyStatus = 'active';
      } else if (link.status === 'pending') {
        buddyStatus =
          link.requestedByUserId === viewerId
            ? 'pending_outgoing'
            : 'pending_incoming';
      }
      buddyByOther.set(otherId, { buddyLinkId: link.id, buddyStatus });
    }

    return users
      .map((u) => {
        const buddy = buddyByOther.get(u.id);
        return {
          userId: u.id,
          displayName: u.displayName || 'Member',
          isTrainingNow: trainingIds.has(u.id),
          buddyStatus: buddy?.buddyStatus ?? 'none',
          buddyLinkId: buddy?.buddyLinkId ?? null,
        };
      })
      .sort((a, b) => {
        // Training now first, then buddies, then A–Z
        if (a.isTrainingNow !== b.isTrainingNow) {
          return a.isTrainingNow ? -1 : 1;
        }
        const aBuddy = a.buddyStatus === 'active' ? 0 : 1;
        const bBuddy = b.buddyStatus === 'active' ? 0 : 1;
        if (aBuddy !== bBuddy) return aBuddy - bBuddy;
        return a.displayName.localeCompare(b.displayName);
      });
  }

  async getProfile(
    viewerId: string,
    viewerGymId: string,
    memberId: string,
    postsLimit: number,
    postsOffset: number,
    { includeContact = false }: { includeContact?: boolean } = {},
  ) {
    const member = await this.prisma.user.findFirst({
      where: { id: memberId, gymId: viewerGymId },
      select: {
        id: true,
        displayName: true,
        email: true,
        phone: true,
        subscriptionTier: true,
        authProviderId: true,
        gym: { select: { id: true, name: true, timezone: true } },
      },
    });
    if (!member) throw new NotFoundException('Member not found');

    const [sessions, routines, staff] = await Promise.all([
      this.prisma.workoutSession.findMany({
        where: {
          userId: memberId,
          gymId: viewerGymId,
          endedAt: { not: null },
          deletedAt: null,
        },
        select: {
          endedAt: true,
          sets: {
            where: { deletedAt: null },
            select: { reps: true, weightKg: true },
          },
        },
      }),
      this.prisma.workoutTemplate.findMany({
        where: {
          createdByUserId: memberId,
          gymId: viewerGymId,
          source: 'user',
          isActive: true,
        },
        include: {
          exercises: {
            include: { exercise: true },
            orderBy: { sortOrder: 'asc' },
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
      member.authProviderId
        ? this.prisma.gymStaff.findFirst({
            where: {
              gymId: viewerGymId,
              authProviderId: member.authProviderId,
            },
            select: { role: true },
          })
        : null,
    ]);
    const posts = await this.social.getMemberPosts(
      viewerGymId,
      memberId,
      viewerId,
      Math.min(Math.max(postsLimit, 1), 50),
      Math.max(postsOffset, 0),
    );

    const totalSets = sessions.reduce((sum, session) => sum + session.sets.length, 0);
    const totalVolume = sessions.reduce(
      (sum, session) =>
        sum +
        session.sets.reduce(
          (setSum, set) =>
            setSum + Number(set.weightKg ?? 0) * (set.reps ?? 0),
          0,
        ),
      0,
    );

    const isOwnProfile = viewerId === member.id;
    // Contact details are private: only the member themselves and gym staff see them.
    const contact =
      includeContact || isOwnProfile
        ? { email: member.email, phone: member.phone }
        : {};

    return {
      memberId: member.id,
      displayName: member.displayName ?? 'Gym member',
      ...contact,
      subscriptionTier: member.subscriptionTier,
      avatarUrl: null,
      staffRole: staff?.role ?? null,
      gym: { id: member.gym.id, name: member.gym.name },
      isOwnProfile,
      stats: {
        workoutCount: sessions.length,
        totalSets,
        totalVolume,
        streakDays: this.calculateStreak(
          sessions
            .map((session) => session.endedAt)
            .filter((date): date is Date => date !== null),
          member.gym.timezone,
        ),
      },
      posts,
      postsHasMore: posts.length === Math.min(Math.max(postsLimit, 1), 50),
      sharedRoutines: routines,
    };
  }

  async updateMember(gymId: string, memberId: string, dto: UpdateMemberDto) {
    const member = await this.prisma.user.findFirst({
      where: { id: memberId, gymId },
      select: { id: true },
    });
    if (!member) throw new NotFoundException('Member not found');

    return this.prisma.user.update({
      where: { id: memberId },
      data: {
        ...(dto.displayName !== undefined ? { displayName: dto.displayName.trim() || null } : {}),
        ...(dto.email !== undefined ? { email: dto.email.trim().toLowerCase() || null } : {}),
        ...(dto.phone !== undefined ? { phone: dto.phone.trim() || null } : {}),
        ...(dto.subscriptionTier !== undefined
          ? { subscriptionTier: dto.subscriptionTier.trim() }
          : {}),
      },
      select: {
        id: true,
        displayName: true,
        email: true,
        phone: true,
        subscriptionTier: true,
        updatedAt: true,
      },
    });
  }

  private calculateStreak(completedAt: Date[], timezone: string) {
    const days = new Set(completedAt.map((date) => this.localDay(date, timezone)));
    if (days.size === 0) return 0;

    const today = this.localDay(new Date(), timezone);
    let cursor = this.utcDay(today);
    let streak = 0;
    if (!days.has(today)) cursor = new Date(cursor.getTime() - 86400000);

    while (days.has(this.dayKey(cursor))) {
      streak += 1;
      cursor = new Date(cursor.getTime() - 86400000);
    }
    return streak;
  }

  private localDay(date: Date, timezone: string) {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone || 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).formatToParts(date);
    const values = Object.fromEntries(
      parts
        .filter((part) => part.type !== 'literal')
        .map((part) => [part.type, part.value]),
    );
    return `${values.year}-${values.month}-${values.day}`;
  }

  private utcDay(day: string) {
    const [year, month, date] = day.split('-').map(Number);
    return new Date(Date.UTC(year, month - 1, date));
  }

  private dayKey(date: Date) {
    return date.toISOString().slice(0, 10);
  }
}
