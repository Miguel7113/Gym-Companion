import { AuthService } from './auth.service';

describe('AuthService app sign-in detects staff from the email', () => {
  const gymId = 'gym-1';
  const staff = { id: 'staff-1', gymId, email: 'coach@gym.com', role: 'coach' };

  function build(staffRow: typeof staff | null) {
    const prisma = {
      gymStaff: { findUnique: jest.fn().mockResolvedValue(staffRow) },
      user: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const roster = { findRosterMatch: jest.fn().mockResolvedValue(null) };
    const supabase = { sendPasswordReset: jest.fn() };
    const service = new AuthService(prisma as any, supabase as any, roster as any);
    return { service, prisma, roster, supabase };
  }

  it('check-member sends staff of this gym to the password step', async () => {
    const { service, roster } = build(staff);

    await expect(
      service.checkMember({ gymId, email: 'Coach@Gym.com' }),
    ).resolves.toEqual({ exists: true, hasPassword: true });
    expect(roster.findRosterMatch).not.toHaveBeenCalled();
  });

  it('check-member ignores staff from another gym', async () => {
    const { service, roster } = build({ ...staff, gymId: 'other-gym' });

    await expect(service.checkMember({ gymId, email: 'coach@gym.com' })).resolves.toEqual({
      exists: false,
      hasPassword: false,
    });
    expect(roster.findRosterMatch).toHaveBeenCalled();
  });

  it('login signs staff in through the coach path', async () => {
    const { service } = build(staff);
    const coachLogin = jest
      .spyOn(service, 'coachLogin')
      .mockResolvedValue({ user: { id: 'u1' }, accessToken: 'a', refreshToken: 'r', role: 'coach' } as any);

    await expect(
      service.login({ gymId, email: 'coach@gym.com', password: 'secret1' }),
    ).resolves.toEqual({ user: { id: 'u1' }, accessToken: 'a', refreshToken: 'r' });
    expect(coachLogin).toHaveBeenCalledWith({ email: 'coach@gym.com', password: 'secret1' });
  });

  it('forgot-password sends a reset to staff who are not on the roster', async () => {
    const { service, supabase } = build(staff);

    await service.forgotPassword({ gymId, email: 'coach@gym.com' });
    expect(supabase.sendPasswordReset).toHaveBeenCalledWith('coach@gym.com');
  });
});
