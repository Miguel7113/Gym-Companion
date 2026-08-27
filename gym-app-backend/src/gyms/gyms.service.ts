import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

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

  async listMembers(gymId: string) {
    return this.prisma.user.findMany({
      where: { gymId },
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
  }

  async getStats(gymId: string) {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const [memberCount, workoutsThisWeek, pendingCount] = await Promise.all([
      this.prisma.user.count({ where: { gymId } }),
      this.prisma.workoutSession.count({
        where: { gymId, startedAt: { gte: weekAgo } },
      }),
      this.prisma.gymRoster.count({ where: { gymId, status: 'pending' } }),
    ]);

    return { memberCount, workoutsThisWeek, pendingCount };
  }
}
