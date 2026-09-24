import { HttpException, HttpStatus } from '@nestjs/common';
import { SocialService } from './social.service';

describe('SocialService rate limits', () => {
  it('blocks a new workout share when the hourly cap is reached', async () => {
    const prisma = {
      workoutSession: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'session-1',
          userId: 'user-1',
          gymId: 'gym-1',
          startedAt: new Date('2026-09-14T10:00:00Z'),
          endedAt: new Date('2026-09-14T10:30:00Z'),
          sets: [],
        }),
      },
      post: {
        findFirst: jest.fn().mockResolvedValue(null),
        count: jest.fn().mockResolvedValue(6),
        create: jest.fn(),
      },
      user: { findUnique: jest.fn() },
      userAchievement: { findMany: jest.fn() },
      gymStaff: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new SocialService(prisma as any, {} as any);

    await expect(
      service.shareWorkout('user-1', 'gym-1', 'session-1', {}),
    ).rejects.toMatchObject({
      status: HttpStatus.TOO_MANY_REQUESTS,
    });
    expect(prisma.post.create).not.toHaveBeenCalled();
  });

  it('allows re-sharing an already shared session without counting against the cap', async () => {
    const existing = {
      id: 'post-1',
      userId: 'user-1',
      gymId: 'gym-1',
      content: 'Already shared',
      imagePath: null,
      imageUrl: null,
      achievementType: 'workout_complete',
      workoutSessionId: 'session-1',
      workoutSession: null,
      likes: [],
      comments: [],
      certification: null,
      isFlagged: false,
      createdAt: new Date(),
      user: { displayName: 'Miguel' },
    };
    const prisma = {
      workoutSession: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'session-1',
          userId: 'user-1',
          gymId: 'gym-1',
          startedAt: new Date(),
          endedAt: new Date(),
          sets: [],
        }),
      },
      post: {
        findFirst: jest.fn().mockResolvedValue(existing),
        count: jest.fn(),
        create: jest.fn(),
      },
      gymStaff: { findFirst: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const service = new SocialService(prisma as any, {} as any);

    const result = await service.shareWorkout('user-1', 'gym-1', 'session-1', {});

    expect(result.id).toBe('post-1');
    expect(prisma.post.count).not.toHaveBeenCalled();
    expect(prisma.post.create).not.toHaveBeenCalled();
  });

  it('blocks comments when the hourly comment cap is reached', async () => {
    const prisma = {
      post: {
        findFirst: jest.fn().mockResolvedValue({ id: 'post-1', gymId: 'gym-1' }),
      },
      postComment: {
        count: jest.fn().mockResolvedValue(30),
        create: jest.fn(),
      },
    };
    const service = new SocialService(prisma as any, {} as any);

    await expect(
      service.createComment('user-1', 'gym-1', 'post-1', { content: 'hi' }),
    ).rejects.toBeInstanceOf(HttpException);
    expect(prisma.postComment.create).not.toHaveBeenCalled();
  });
});
