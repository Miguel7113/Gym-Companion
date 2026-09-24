import { MembersService } from './members.service';

describe('MembersService', () => {
  it('returns only same-gym public profile data and shared routines', async () => {
    const prisma = {
      user: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'member-1',
          displayName: 'Member One',
          authProviderId: 'auth-1',
          gym: { id: 'gym-1', name: 'Gym One', timezone: 'UTC' },
        }),
      },
      workoutSession: {
        findMany: jest.fn().mockResolvedValue([
          {
            endedAt: new Date(),
            sets: [{ reps: 5, weightKg: 100 }],
          },
        ]),
      },
      workoutTemplate: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'shared-routine', gymId: 'gym-1', exercises: [] },
        ]),
      },
      gymStaff: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const social = { getMemberPosts: jest.fn().mockResolvedValue([]) };
    const service = new MembersService(prisma as any, social as any);

    const result = await service.getProfile(
      'viewer-1',
      'gym-1',
      'member-1',
      20,
      0,
    );

    expect(result.memberId).toBe('member-1');
    expect(result.stats.workoutCount).toBe(1);
    expect(result.stats.totalVolume).toBe(500);
    expect(result.sharedRoutines).toHaveLength(1);
    expect(result).not.toHaveProperty('email');
    expect(result).not.toHaveProperty('phone');
    expect(prisma.workoutTemplate.findMany.mock.calls[0][0].where).toEqual(
      expect.objectContaining({
        createdByUserId: 'member-1',
        gymId: 'gym-1',
        source: 'user',
        isActive: true,
      }),
    );
  });

  it('includes contact details only for staff or the member themselves', async () => {
    const makeService = () => {
      const prisma = {
        user: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'member-1',
            displayName: 'Member One',
            email: 'one@example.com',
            phone: '+100',
            authProviderId: null,
            gym: { id: 'gym-1', name: 'Gym One', timezone: 'UTC' },
          }),
        },
        workoutSession: { findMany: jest.fn().mockResolvedValue([]) },
        workoutTemplate: { findMany: jest.fn().mockResolvedValue([]) },
        gymStaff: { findFirst: jest.fn().mockResolvedValue(null) },
      };
      const social = { getMemberPosts: jest.fn().mockResolvedValue([]) };
      return new MembersService(prisma as any, social as any);
    };

    const peer = await makeService().getProfile('viewer-1', 'gym-1', 'member-1', 20, 0);
    expect(peer).not.toHaveProperty('email');
    expect(peer).not.toHaveProperty('phone');

    const own = await makeService().getProfile('member-1', 'gym-1', 'member-1', 20, 0);
    expect(own).toMatchObject({ email: 'one@example.com', phone: '+100' });

    const staff = await makeService().getProfile('staff:s1', 'gym-1', 'member-1', 20, 0, {
      includeContact: true,
    });
    expect(staff).toMatchObject({ email: 'one@example.com', phone: '+100' });
  });

  it('does not allow cross-gym member lookup', async () => {
    const prisma = {
      user: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new MembersService(prisma as any, {} as any);

    await expect(
      service.getProfile('viewer-1', 'gym-1', 'member-from-gym-2', 20, 0),
    ).rejects.toThrow('Member not found');
  });
});
