import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService.staffLogin', () => {
  const staffRow = {
    id: 'staff-1',
    gymId: 'gym-1',
    email: 'coach@gym.com',
    role: 'admin',
    authProviderId: 'auth-1',
  };

  function build(staff: typeof staffRow | null, signIn: jest.Mock) {
    const prisma = {
      gymStaff: {
        findUnique: jest.fn().mockResolvedValue(staff),
        update: jest.fn(),
      },
    };
    const supabase = { signInWithPassword: signIn };
    return new AuthService(prisma as any, supabase as any, {} as any);
  }

  it('returns 401 for a wrong password instead of leaking the auth error', async () => {
    const signIn = jest.fn().mockRejectedValue(new Error('Invalid login credentials'));
    const service = build(staffRow, signIn);

    await expect(
      service.staffLogin({ email: 'Coach@Gym.com', password: 'nope' }),
    ).rejects.toThrow(UnauthorizedException);
    expect(signIn).toHaveBeenCalledWith('coach@gym.com', 'nope');
  });

  it('returns the same 401 for an email that is not staff', async () => {
    const signIn = jest.fn();
    const service = build(null, signIn);

    await expect(
      service.staffLogin({ email: 'nobody@example.com', password: 'x' }),
    ).rejects.toThrow('Incorrect email or password.');
    expect(signIn).not.toHaveBeenCalled();
  });

  it('returns tokens for valid staff credentials', async () => {
    const signIn = jest.fn().mockResolvedValue({
      user: { id: 'auth-1' },
      access_token: 'access',
      refresh_token: 'refresh',
    });
    const service = build(staffRow, signIn);

    await expect(
      service.staffLogin({ email: 'coach@gym.com', password: 'right' }),
    ).resolves.toMatchObject({
      accessToken: 'access',
      staff: { id: 'staff-1', gymId: 'gym-1' },
    });
  });
});
