import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

const MAX_ACTIVE_BUDDIES = 3;

function pairIds(a: string, b: string): [string, string] {
  return a < b ? [a, b] : [b, a];
}

@Injectable()
export class BuddiesService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async list(userId: string, gymId: string) {
    const links = await this.prisma.gymBuddyLink.findMany({
      where: {
        gymId,
        OR: [{ userAId: userId }, { userBId: userId }],
        status: { in: ['pending', 'active'] },
      },
      include: {
        userA: { select: { id: true, displayName: true, email: true } },
        userB: { select: { id: true, displayName: true, email: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return links.map((link) => {
      const other = link.userAId === userId ? link.userB : link.userA;
      return {
        id: link.id,
        status: link.status,
        requestedByUserId: link.requestedByUserId,
        isIncoming: link.status === 'pending' && link.requestedByUserId !== userId,
        otherUser: {
          id: other.id,
          displayName: other.displayName || other.email || 'Member',
          email: other.email,
        },
        createdAt: link.createdAt,
        updatedAt: link.updatedAt,
      };
    });
  }

  async searchMembers(userId: string, gymId: string, q?: string) {
    const query = (q ?? '').trim();
    const users = await this.prisma.user.findMany({
      where: {
        gymId,
        id: { not: userId },
        ...(query
          ? {
              OR: [
                { displayName: { contains: query, mode: 'insensitive' } },
                { email: { contains: query, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      select: { id: true, displayName: true, email: true },
      take: 30,
      orderBy: { displayName: 'asc' },
    });

    return users.map((u) => ({
      id: u.id,
      displayName: u.displayName || u.email || 'Member',
      email: u.email,
    }));
  }

  async request(userId: string, gymId: string, toUserId: string) {
    if (toUserId === userId) {
      throw new BadRequestException('Cannot buddy yourself');
    }

    const target = await this.prisma.user.findFirst({
      where: { id: toUserId, gymId },
      select: { id: true, displayName: true, email: true },
    });
    if (!target) throw new NotFoundException('Member not found in this gym');

    await this.assertUnderBuddyCap(userId, gymId);
    await this.assertUnderBuddyCap(toUserId, gymId);

    const [userAId, userBId] = pairIds(userId, toUserId);
    const existing = await this.prisma.gymBuddyLink.findUnique({
      where: {
        gymId_userAId_userBId: { gymId, userAId, userBId },
      },
    });

    if (existing?.status === 'active') {
      throw new ConflictException('Already buddies');
    }
    if (existing?.status === 'pending') {
      throw new ConflictException('Buddy request already pending');
    }

    const link = existing
      ? await this.prisma.gymBuddyLink.update({
          where: { id: existing.id },
          data: {
            status: 'pending',
            requestedByUserId: userId,
          },
        })
      : await this.prisma.gymBuddyLink.create({
          data: {
            id: crypto.randomUUID(),
            gymId,
            userAId,
            userBId,
            requestedByUserId: userId,
            status: 'pending',
          },
        });

    const from = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { displayName: true, email: true },
    });
    const fromName = from?.displayName || from?.email || 'A member';

    await this.notifications.create({
      gymId,
      userId: toUserId,
      type: 'buddy_request',
      title: 'Gym buddy request',
      body: `${fromName} wants to be your gym buddy.`,
      payload: { buddyLinkId: link.id, fromUserId: userId },
    });

    return link;
  }

  async accept(userId: string, gymId: string, linkId: string) {
    const link = await this.requireIncomingPending(userId, gymId, linkId);
    await this.assertUnderBuddyCap(link.userAId, gymId);
    await this.assertUnderBuddyCap(link.userBId, gymId);

    const updated = await this.prisma.gymBuddyLink.update({
      where: { id: linkId },
      data: { status: 'active' },
    });

    const accepter = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { displayName: true, email: true },
    });
    const name = accepter?.displayName || accepter?.email || 'Your buddy';

    await this.notifications.create({
      gymId,
      userId: link.requestedByUserId,
      type: 'buddy_accepted',
      title: 'Buddy request accepted',
      body: `${name} accepted your gym buddy request.`,
      payload: { buddyLinkId: link.id },
    });

    return updated;
  }

  async decline(userId: string, gymId: string, linkId: string) {
    await this.requireIncomingPending(userId, gymId, linkId);
    return this.prisma.gymBuddyLink.update({
      where: { id: linkId },
      data: { status: 'declined' },
    });
  }

  async cancel(userId: string, gymId: string, linkId: string) {
    const link = await this.prisma.gymBuddyLink.findFirst({
      where: {
        id: linkId,
        gymId,
        OR: [{ userAId: userId }, { userBId: userId }],
      },
    });
    if (!link) throw new NotFoundException('Buddy link not found');

    return this.prisma.gymBuddyLink.update({
      where: { id: linkId },
      data: { status: 'cancelled' },
    });
  }

  async assertActiveBuddy(userId: string, buddyUserId: string, gymId: string) {
    const [userAId, userBId] = pairIds(userId, buddyUserId);
    const link = await this.prisma.gymBuddyLink.findFirst({
      where: {
        gymId,
        userAId,
        userBId,
        status: 'active',
      },
    });
    if (!link) {
      throw new ForbiddenException('You can only train with an active gym buddy');
    }
    return link;
  }

  private async assertUnderBuddyCap(userId: string, gymId: string) {
    const count = await this.prisma.gymBuddyLink.count({
      where: {
        gymId,
        status: 'active',
        OR: [{ userAId: userId }, { userBId: userId }],
      },
    });
    if (count >= MAX_ACTIVE_BUDDIES) {
      throw new BadRequestException(
        `Maximum of ${MAX_ACTIVE_BUDDIES} active gym buddies allowed`,
      );
    }
  }

  private async requireIncomingPending(
    userId: string,
    gymId: string,
    linkId: string,
  ) {
    const link = await this.prisma.gymBuddyLink.findFirst({
      where: { id: linkId, gymId, status: 'pending' },
    });
    if (!link) throw new NotFoundException('Pending request not found');
    if (link.requestedByUserId === userId) {
      throw new ForbiddenException('Cannot accept your own request');
    }
    if (link.userAId !== userId && link.userBId !== userId) {
      throw new ForbiddenException();
    }
    return link;
  }
}
