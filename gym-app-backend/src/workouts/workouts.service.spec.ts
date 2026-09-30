import { WorkoutsService } from './workouts.service';

describe('WorkoutsService routine runs', () => {
  it('persists the routine identity when creating a session', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'session-1' });
    const prisma = {
      workoutTemplate: { findFirst: jest.fn().mockResolvedValue({ id: 'routine-1' }) },
      workoutSession: { create },
    };
    const service = new WorkoutsService(prisma as any, {} as any, {} as any);

    await service.createSession('member-1', 'gym-1', {
      templateId: 'routine-1',
      notes: 'Push day',
    });

    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'member-1',
          gymId: 'gym-1',
          templateId: 'routine-1',
        }),
      }),
    );
  });

  it('only ranks sessions with a certified workout post', async () => {
    const routine = {
      id: 'routine-1',
      exercises: [{ exerciseId: 'bench' }],
    };
    const findRoutine = jest.fn().mockResolvedValue(routine);
    const findSessions = jest.fn().mockResolvedValue([
      {
        user: { id: 'member-1', displayName: 'Member One' },
        sets: [{ reps: 8, weightKg: 100 }],
        sharedPost: {
          certification: {
            createdAt: new Date('2026-08-31T10:00:00Z'),
            coach: { displayName: 'Coach One' },
          },
        },
      },
      {
        user: { id: 'member-2', displayName: 'Uncertified Member' },
        sets: [{ reps: 12, weightKg: 200 }],
        sharedPost: { certification: null },
      },
    ]);
    const prisma = {
      workoutTemplate: { findFirst: findRoutine },
      workoutSession: { findMany: findSessions },
    };
    const service = new WorkoutsService(prisma as any, {} as any, {} as any);

    const result = await service.getRoutineLeaderboard(
      'viewer',
      'gym-1',
      'routine-1',
      'bench',
      'volume',
    );

    expect(result.entries).toHaveLength(1);
    expect(result.entries[0]).toEqual(
      expect.objectContaining({
        userId: 'member-1',
        value: 800,
        coachName: 'Coach One',
      }),
    );
    expect(findSessions.mock.calls[0][0].where.gymId).toBe('gym-1');
    expect(findSessions.mock.calls[0][0].where.sharedPost.certification).toEqual({
      isNot: null,
    });
  });

  it('treats multiple equipment filters as any-of', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const prisma = { exercise: { findMany } };
    const service = new WorkoutsService(prisma as any, {} as any, {} as any);

    await service.listExercises(undefined, undefined, undefined, 'barbell, cable');

    expect(findMany.mock.calls[0][0].where.equipments).toEqual({
      hasSome: ['barbell', 'cable'],
    });
  });

  it('rejects an avatar stored outside the member folder', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({ authProviderId: 'auth-1' }),
        update: jest.fn(),
      },
    };
    const service = new WorkoutsService(prisma as any, {} as any, {} as any);

    await expect(
      service.updateProfile('user-1', { avatarPath: 'someone-else/avatar.jpg' }),
    ).rejects.toThrow('Avatar must be stored in your own folder');
    expect(prisma.user.update).not.toHaveBeenCalled();
  });
});
