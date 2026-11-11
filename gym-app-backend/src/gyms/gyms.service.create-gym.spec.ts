import { BadRequestException, ConflictException } from '@nestjs/common';
import { GymsService } from './gyms.service';

describe('GymsService.createGymWithAdmin', () => {
  const input = {
    name: 'Test Gym B',
    adminEmail: 'Owner+B@Gmail.com',
    adminPassword: 'long-enough-1',
    primaryColor: '#FF7A00',
    timezone: 'Africa/Nairobi',
  };

  function build({ sameName = null, staff = null } = {} as { sameName?: unknown; staff?: unknown }) {
    const prisma = {
      gym: {
        findFirst: jest.fn().mockResolvedValue(sameName),
        create: jest.fn().mockImplementation(({ data }) => ({ id: 'gym-b', ...data })),
        delete: jest.fn().mockResolvedValue({}),
      },
      gymStaff: { findUnique: jest.fn().mockResolvedValue(staff) },
    };
    const auth = { staffInvite: jest.fn().mockResolvedValue({}) };
    const service = new GymsService(prisma as any, auth as any);
    return { service, prisma, auth };
  }

  it('creates the gym and invites its admin', async () => {
    const { service, prisma, auth } = build();

    const result = await service.createGymWithAdmin(input);

    expect(result.adminEmail).toBe('owner+b@gmail.com');
    expect(prisma.gym.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        name: 'Test Gym B',
        primaryColor: '#FF7A00',
        timezone: 'Africa/Nairobi',
        contactEmail: 'owner+b@gmail.com',
      }),
    });
    expect(auth.staffInvite).toHaveBeenCalledWith('gym-b', {
      email: 'owner+b@gmail.com',
      password: 'long-enough-1',
      role: 'admin',
    });
  });

  it.each([
    [{ name: ' ' }, 'Gym name'],
    [{ adminEmail: 'nope' }, 'Admin email'],
    [{ adminPassword: 'short' }, '8 characters'],
    [{ primaryColor: 'orange' }, 'Colour'],
    [{ timezone: 'Mars/Base' }, 'timezone'],
  ])('rejects bad input %o before writing anything', async (override, message) => {
    const { service, prisma } = build();

    const attempt = service.createGymWithAdmin({ ...input, ...override });
    await expect(attempt).rejects.toBeInstanceOf(BadRequestException);
    await expect(attempt).rejects.toThrow(message);
    expect(prisma.gym.create).not.toHaveBeenCalled();
  });

  it('refuses a duplicate gym name or an email that is already staff', async () => {
    await expect(
      build({ sameName: { id: 'g1' } }).service.createGymWithAdmin(input),
    ).rejects.toBeInstanceOf(ConflictException);
    await expect(
      build({ staff: { id: 's1' } }).service.createGymWithAdmin(input),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('removes the gym again when the admin cannot be created', async () => {
    const { service, prisma, auth } = build();
    auth.staffInvite.mockRejectedValue(new Error('email already registered'));

    await expect(service.createGymWithAdmin(input)).rejects.toThrow('already registered');
    expect(prisma.gym.delete).toHaveBeenCalledWith({ where: { id: 'gym-b' } });
  });
});
