import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  create(params: {
    gymId: string;
    userId: string;
    type: string;
    title: string;
    body: string;
    payload?: Record<string, unknown>;
  }) {
    return this.prisma.appNotification.create({
      data: {
        id: crypto.randomUUID(),
        gymId: params.gymId,
        userId: params.userId,
        type: params.type,
        title: params.title,
        body: params.body,
        payload: (params.payload ?? Prisma.JsonNull) as Prisma.InputJsonValue,
      },
    });
  }

  list(userId: string, gymId: string, limit = 50) {
    return this.prisma.appNotification.findMany({
      where: { userId, gymId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async markRead(userId: string, notificationId: string) {
    const existing = await this.prisma.appNotification.findFirst({
      where: { id: notificationId, userId },
    });
    if (!existing) return { updated: false };
    await this.prisma.appNotification.update({
      where: { id: notificationId },
      data: { readAt: new Date() },
    });
    return { updated: true };
  }

  async markAllRead(userId: string, gymId: string) {
    await this.prisma.appNotification.updateMany({
      where: { userId, gymId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: true };
  }
}
