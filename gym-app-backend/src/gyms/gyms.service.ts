import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateGymSettingsDto } from './dto/update-gym-settings.dto';

@Injectable()
export class GymsService {
  constructor(private prisma: PrismaService) {}

  listActive() {
    return this.prisma.gym.findMany({
      where: { isActive: true },
      select: {
        id: true,
        name: true,
        logoUrl: true,
        primaryColor: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  async getById(id: string) {
    const gym = await this.prisma.gym.findFirst({
      where: { id, isActive: true },
      select: {
        id: true,
        name: true,
        logoUrl: true,
        primaryColor: true,
      },
    });
    if (!gym) throw new NotFoundException('Gym not found');
    return gym;
  }

  async getSettings(gymId: string) {
    const gym = await this.prisma.gym.findUnique({
      where: { id: gymId },
      select: {
        id: true,
        name: true,
        logoUrl: true,
        primaryColor: true,
        timezone: true,
        contactEmail: true,
        subscriptionTier: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!gym) throw new NotFoundException('Gym not found');
    return gym;
  }

  async updateSettings(gymId: string, dto: UpdateGymSettingsDto) {
    await this.getSettings(gymId);

    return this.prisma.gym.update({
      where: { id: gymId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.logoUrl !== undefined ? { logoUrl: dto.logoUrl.trim() || null } : {}),
        ...(dto.primaryColor !== undefined ? { primaryColor: dto.primaryColor.trim() } : {}),
        ...(dto.timezone !== undefined ? { timezone: dto.timezone.trim() } : {}),
        ...(dto.contactEmail !== undefined
          ? { contactEmail: dto.contactEmail.trim() || null }
          : {}),
        ...(dto.subscriptionTier !== undefined
          ? { subscriptionTier: dto.subscriptionTier.trim() }
          : {}),
      },
      select: {
        id: true,
        name: true,
        logoUrl: true,
        primaryColor: true,
        timezone: true,
        contactEmail: true,
        subscriptionTier: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async listMembers(gymId: string, q?: string) {
    const query = q?.trim();
    const members = await this.prisma.user.findMany({
      where: {
        gymId,
        ...(query
          ? {
              OR: [
                { displayName: { contains: query, mode: 'insensitive' } },
                { email: { contains: query, mode: 'insensitive' } },
                { phone: { contains: query, mode: 'insensitive' } },
                { id: { equals: query } },
              ],
            }
          : {}),
      },
      select: {
        id: true,
        email: true,
        phone: true,
        displayName: true,
        subscriptionTier: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (members.length === 0) return [];

    const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const ids = members.map((m) => m.id);
    const [lastRows, recentRows] = await Promise.all([
      this.prisma.workoutSession.groupBy({
        by: ['userId'],
        where: { gymId, deletedAt: null, userId: { in: ids } },
        _max: { startedAt: true },
      }),
      this.prisma.workoutSession.groupBy({
        by: ['userId'],
        where: {
          gymId,
          deletedAt: null,
          userId: { in: ids },
          startedAt: { gte: since },
        },
        _count: { _all: true },
      }),
    ]);

    const lastByUser = new Map(
      lastRows.map((row) => [row.userId, row._max.startedAt]),
    );
    const recentByUser = new Map(
      recentRows.map((row) => [row.userId, row._count._all]),
    );

    return members.map((member) => ({
      ...member,
      lastWorkoutAt: lastByUser.get(member.id) ?? null,
      workoutsLast30Days: recentByUser.get(member.id) ?? 0,
    }));
  }

  async getStats(gymId: string) {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const [memberCount, workoutsThisWeek, pendingCount, flaggedCount] =
      await Promise.all([
        this.prisma.user.count({ where: { gymId } }),
        this.prisma.workoutSession.count({
          where: { gymId, startedAt: { gte: weekAgo } },
        }),
        this.prisma.gymRoster.count({ where: { gymId, status: 'pending' } }),
        this.prisma.post.count({
          where: { gymId, isFlagged: true, isDeleted: false },
        }),
      ]);

    return { memberCount, workoutsThisWeek, pendingCount, flaggedCount };
  }
}
