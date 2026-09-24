import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseService } from '../supabase/supabase.service';
import { RosterService } from '../roster/roster.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { ClaimSessionDto } from './dto/claim-session.dto';
import { CheckMemberDto } from './dto/check-member.dto';
import { LoginDto } from './dto/login.dto';
import { SetPasswordDto } from './dto/set-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import {
  StaffInviteDto,
  StaffLoginDto,
  UpdateStaffRoleDto,
} from './dto/staff-auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private supabase: SupabaseService,
    private roster: RosterService,
  ) {}

  async requestOtp(dto: RequestOtpDto) {
    const match = await this.roster.findRosterMatch(dto.gymId, dto.email, dto.phone);

    if (!match) {
      await this.roster.createPendingRequest(dto.gymId, dto.email, dto.phone, dto.displayName);
      return { status: 'pending_approval' as const };
    }

    if (match.status === 'matched') {
      if (dto.email) await this.supabase.sendEmailOtp(dto.email);
      else await this.supabase.sendPhoneOtp(dto.phone!);
      return { status: 'otp_sent' as const, returning: true };
    }

    if (dto.email) await this.supabase.sendEmailOtp(dto.email);
    else await this.supabase.sendPhoneOtp(dto.phone!);

    return { status: 'otp_sent' as const, returning: false };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const match = await this.roster.findRosterMatch(dto.gymId, dto.email, dto.phone);
    if (!match || match.status === 'pending') {
      throw new ConflictException('Not authorized for this gym yet.');
    }

    const session = await this.supabase.verifyOtp({
      email: dto.email,
      phone: dto.phone,
      token: dto.token,
    });

    if (!session?.user?.id) {
      throw new ConflictException('OTP verification failed.');
    }

    const authProviderId = session.user.id;

    let user = await this.prisma.user.findUnique({
      where: { authProviderId },
      select: {
        id: true,
        gymId: true,
        rosterId: true,
        email: true,
        phone: true,
        displayName: true,
        authProviderId: true,
      },
    });

    if (!user) {
      if (match.status === 'matched') {
        throw new ConflictException('An account already exists for this member.');
      }

      user = await this.prisma.user.create({
        data: {
          gymId: dto.gymId,
          rosterId: match.id,
          email: dto.email,
          phone: dto.phone,
          displayName: dto.displayName ?? match.memberName ?? undefined,
          authProviderId,
        },
        select: {
          id: true,
          gymId: true,
          rosterId: true,
          email: true,
          phone: true,
          displayName: true,
          authProviderId: true,
        },
      });

      await this.roster.markMatched(match.id, user.id);
    }

    // ── Inject gym_id, member_id, role into JWT claims ────────────────────
    // This is REQUIRED for RLS policies to work — the JWT must contain
    // these values so the helper functions get_my_gym_id() etc. return correctly.
    // Check if this user is also a staff member to determine their role.
    const staffRecord = await this.prisma.gymStaff.findFirst({
      where: { gymId: dto.gymId, authProviderId },
    });
    const role = staffRecord?.role ?? 'member';

    await this.supabase.updateUserMetadata(authProviderId, {
      gym_id: dto.gymId,
      member_id: user.id,
      role,
      display_name: user.displayName ?? null,
    });

    // Refresh the session so the new JWT claims are live
    const refreshedSession = await this.supabase.refreshSession(session.refresh_token!);

    return {
      user,
      accessToken: refreshedSession.access_token,
      refreshToken: refreshedSession.refresh_token,
    };
  }

  // ── Magic link claim ─────────────────────────────────────────────────────
  // Called after Supabase magic link opens the app. Flutter passes both tokens
  // from the magic link session. Flow:
  //   1. Verify accessToken with Supabase admin — confirms session is valid
  //   2. Find gym_roster match by email / phone across all gyms
  //   3. Create or find the users row in our DB
  //   4. Inject gym_id / member_id / role / display_name into JWT metadata
  //   5. Refresh using the refreshToken Flutter sent — new JWT has gym claims
  async claimSession(accessToken: string, dto: ClaimSessionDto) {
    // 1. Verify the access token
    const supabaseUser = await this.supabase.getUser(accessToken);
    if (!supabaseUser?.id) {
      throw new UnauthorizedException('Invalid or expired session token.');
    }

    const authProviderId = supabaseUser.id;
    const email = dto.email ?? supabaseUser.email;
    const phone = dto.phone ?? supabaseUser.phone;

    // 2. Find roster match across all gyms
    const rosterMatch = await this.roster.findRosterMatchAnyGym(email, phone);
    if (!rosterMatch) {
      throw new UnauthorizedException(
        'No gym membership found for this account. Contact your gym.',
      );
    }

    const gymId = rosterMatch.gymId;

    // 3. Create or find users row
    // Use a minimal select to avoid touching columns that may not exist yet
    // in the DB if migrations are behind the schema (e.g. body_weight_kg).
    let user = await this.prisma.user.findUnique({
      where: { authProviderId },
      select: {
        id: true,
        gymId: true,
        rosterId: true,
        email: true,
        phone: true,
        displayName: true,
        authProviderId: true,
      },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          gymId,
          rosterId: rosterMatch.id,
          email,
          phone,
          displayName: dto.displayName ?? rosterMatch.memberName ?? undefined,
          authProviderId,
        },
        select: {
          id: true,
          gymId: true,
          rosterId: true,
          email: true,
          phone: true,
          displayName: true,
          authProviderId: true,
        },
      });
      await this.roster.markMatched(rosterMatch.id, user.id);
    }

    // 4. Inject JWT claims
    const staffRecord = await this.prisma.gymStaff.findFirst({
      where: { gymId, authProviderId },
    });
    const role = staffRecord?.role ?? 'member';

    await this.supabase.updateUserMetadata(authProviderId, {
      gym_id: gymId,
      member_id: user.id,
      role,
      display_name: user.displayName ?? null,
    });

    // 5. Refresh using the token Flutter passed — the new JWT will contain
    //    the gym claims we just injected via updateUserMetadata
    const refreshedSession = await this.supabase.refreshSession(dto.refreshToken);

    return {
      user,
      accessToken: refreshedSession.access_token,
      refreshToken: refreshedSession.refresh_token,
    };
  }

  // ── Check member ─────────────────────────────────────────────────────────
  // Lightweight pre-check before showing any auth form.
  // Returns:
  //   { exists: false }               → not on roster → show "contact gym admin" error
  //   { exists: true, hasPassword: false } → new member → proceed with OTP/magic link
  //   { exists: true, hasPassword: true }  → returning member → show LoginScreen
  async checkMember(dto: CheckMemberDto) {
    const rosterMatch = await this.roster.findRosterMatch(
      dto.gymId,
      dto.email,
      dto.phone,
    );

    if (!rosterMatch || rosterMatch.status === 'pending') {
      return { exists: false, hasPassword: false };
    }

    // Check if a users row exists AND has password_set flag in Supabase metadata
    const user = await this.prisma.user.findFirst({
      where: {
        gymId: dto.gymId,
        OR: [
          dto.email ? { email: dto.email.toLowerCase() } : undefined,
          dto.phone ? { phone: dto.phone } : undefined,
        ].filter(Boolean) as any,
      },
      select: { authProviderId: true },
    });

    if (!user?.authProviderId) {
      // On roster but never completed signup
      return { exists: true, hasPassword: false };
    }

    // Check Supabase metadata for password_set flag
    const supabaseUser = await this.supabase.getUserById(user.authProviderId);
    const hasPassword = supabaseUser?.user_metadata?.password_set === true;

    return { exists: true, hasPassword };
  }

  // ── Password login ────────────────────────────────────────────────────────
  // Day-to-day login for returning members. No OTP, no magic link.
  async login(dto: LoginDto) {
    // 1. Confirm still on roster (catches expelled members)
    const rosterMatch = await this.roster.findRosterMatch(
      dto.gymId,
      dto.email,
      undefined,
    );
    if (!rosterMatch || rosterMatch.status === 'pending') {
      throw new UnauthorizedException(
        'Your account was not found as a current gym member. Contact your gym admin.',
      );
    }

    // 2. Sign in with Supabase — wrong password throws automatically
    let session: Awaited<ReturnType<typeof this.supabase.signInWithPassword>>;
    try {
      session = await this.supabase.signInWithPassword(dto.email, dto.password);
    } catch {
      throw new UnauthorizedException('Incorrect email or password.');
    }

    if (!session?.user?.id) {
      throw new UnauthorizedException('Login failed. Please try again.');
    }

    const authProviderId = session.user.id;

    // 3. Find or create users row (handles edge case of account existing in
    //    Supabase but users row missing)
    let user = await this.prisma.user.findUnique({
      where: { authProviderId },
      select: { id: true, gymId: true, displayName: true, authProviderId: true },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          gymId: dto.gymId,
          rosterId: rosterMatch.id,
          email: dto.email.toLowerCase(),
          authProviderId,
          displayName: rosterMatch.memberName ?? undefined,
        },
        select: { id: true, gymId: true, displayName: true, authProviderId: true },
      });
      await this.roster.markMatched(rosterMatch.id, user.id);
    }

    // 4. Inject / refresh JWT claims
    const staffRecord = await this.prisma.gymStaff.findFirst({
      where: { gymId: dto.gymId, authProviderId },
    });
    const role = staffRecord?.role ?? 'member';

    await this.supabase.updateUserMetadata(authProviderId, {
      gym_id: dto.gymId,
      member_id: user.id,
      role,
      display_name: user.displayName ?? null,
      password_set: true,
    });

    const refreshedSession = await this.supabase.refreshSession(session.refresh_token!);

    return {
      user,
      accessToken: refreshedSession.access_token,
      refreshToken: refreshedSession.refresh_token,
    };
  }

  // ── Set password ──────────────────────────────────────────────────────────
  // Called once after first OTP/magic link verification.
  // The Bearer token in the Authorization header is the just-verified session.
  async setPasswordFromToken(accessToken: string, dto: SetPasswordDto) {
    const supabaseUser = await this.supabase.getUser(accessToken);
    if (!supabaseUser?.id) {
      throw new UnauthorizedException('Invalid or expired session token.');
    }
    return this.setPassword(supabaseUser.id, dto);
  }

  async setPassword(authProviderId: string, dto: SetPasswordDto) {
    await this.supabase.setUserPassword(authProviderId, dto.password);

    // Mark password_set in metadata so _AuthGate knows not to show SetPassword again
    const existingUser = await this.supabase.getUserById(authProviderId);
    await this.supabase.updateUserMetadata(authProviderId, {
      ...(existingUser?.user_metadata ?? {}),
      password_set: true,
    });

    return { success: true };
  }
  // ── Forgot password ───────────────────────────────────────────────────────
  // Confirms the email is still on the gym roster, then triggers a Supabase
  // password reset email. The reset link deep-links to the SetPassword screen.
  async forgotPassword(dto: ForgotPasswordDto) {
    const rosterMatch = await this.roster.findRosterMatch(
      dto.gymId,
      dto.email,
      undefined,
    );

    // Always return success — don't reveal whether an email is on the roster
    // to prevent enumeration attacks. The member will only get an email if
    // they're actually registered.
    if (rosterMatch && rosterMatch.status !== 'pending') {
      await this.supabase.sendPasswordReset(dto.email);
    }

    return { sent: true };
  }

  async staffLogin(dto: StaffLoginDto) {
    const session = await this.supabase.signInWithPassword(dto.email, dto.password);
    const staff = await this.prisma.gymStaff.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (!staff) {
      throw new ConflictException('Not a registered staff member.');
    }

    if (!staff.authProviderId && session.user?.id) {
      await this.prisma.gymStaff.update({
        where: { id: staff.id },
        data: { authProviderId: session.user.id },
      });
    }

    return {
      staff: { id: staff.id, gymId: staff.gymId, email: staff.email, role: staff.role },
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
    };
  }

  /**
   * App coach/admin login — returns a member-shaped JWT (gym claims + role)
   * so Flutter can use the same SupabaseAuthGuard paths as members.
   */
  async coachLogin(dto: StaffLoginDto) {
    const email = dto.email.toLowerCase();
    const staff = await this.prisma.gymStaff.findUnique({ where: { email } });
    if (!staff) {
      throw new ForbiddenException('No coach account for this gym.');
    }

    let session: Awaited<ReturnType<typeof this.supabase.signInWithPassword>>;
    try {
      session = await this.supabase.signInWithPassword(email, dto.password);
    } catch {
      throw new UnauthorizedException('Incorrect email or password.');
    }

    if (!session?.user?.id) {
      throw new UnauthorizedException('Login failed. Please try again.');
    }

    const authProviderId = session.user.id;
    if (!staff.authProviderId) {
      await this.prisma.gymStaff.update({
        where: { id: staff.id },
        data: { authProviderId },
      });
    }

    const user = await this.ensureStaffAppUser({
      gymId: staff.gymId,
      email,
      authProviderId,
      role: staff.role,
      memberName: email.split('@')[0] ?? 'Coach',
    });

    await this.supabase.updateUserMetadata(authProviderId, {
      gym_id: staff.gymId,
      member_id: user.id,
      role: staff.role,
      display_name: user.displayName ?? null,
      password_set: true,
    });

    const refreshedSession = await this.supabase.refreshSession(session.refresh_token!);

    return {
      user,
      accessToken: refreshedSession.access_token,
      refreshToken: refreshedSession.refresh_token,
      role: staff.role,
    };
  }

  async staffInvite(gymId: string, dto: StaffInviteDto) {
    const email = dto.email.toLowerCase();
    const existing = await this.prisma.gymStaff.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('Staff email already registered.');
    }

    const role = dto.role ?? 'admin';
    const authUser = await this.supabase.createStaffUser(email, dto.password);

    const staff = await this.prisma.gymStaff.create({
      data: {
        gymId,
        email,
        role,
        authProviderId: authUser.id,
      },
    });

    const user = await this.ensureStaffAppUser({
      gymId,
      email,
      authProviderId: authUser.id,
      role,
      memberName: email.split('@')[0] ?? 'Coach',
    });

    await this.supabase.updateUserMetadata(authUser.id, {
      gym_id: gymId,
      member_id: user.id,
      role,
      display_name: user.displayName ?? null,
      password_set: true,
    });

    return { staff, user };
  }

  /** Ensure roster + users row for a staff member so app JWT paths work. */
  private async ensureStaffAppUser(params: {
    gymId: string;
    email: string;
    authProviderId: string;
    role: string;
    memberName: string;
  }) {
    const { gymId, email, authProviderId, memberName } = params;

    let user = await this.prisma.user.findUnique({
      where: { authProviderId },
      select: {
        id: true,
        gymId: true,
        rosterId: true,
        email: true,
        phone: true,
        displayName: true,
        authProviderId: true,
      },
    });

    if (user) {
      return user;
    }

    user = await this.prisma.user.findFirst({
      where: { gymId, email },
      select: {
        id: true,
        gymId: true,
        rosterId: true,
        email: true,
        phone: true,
        displayName: true,
        authProviderId: true,
      },
    });

    if (user) {
      if (!user.authProviderId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { authProviderId },
          select: {
            id: true,
            gymId: true,
            rosterId: true,
            email: true,
            phone: true,
            displayName: true,
            authProviderId: true,
          },
        });
      }
      return user;
    }

    let roster = await this.prisma.gymRoster.findFirst({
      where: { gymId, email },
    });

    if (!roster) {
      roster = await this.prisma.gymRoster.create({
        data: {
          gymId,
          email,
          memberName,
          status: 'matched',
        },
      });
    }

    user = await this.prisma.user.create({
      data: {
        gymId,
        rosterId: roster.id,
        email,
        displayName: roster.memberName ?? memberName,
        authProviderId,
      },
      select: {
        id: true,
        gymId: true,
        rosterId: true,
        email: true,
        phone: true,
        displayName: true,
        authProviderId: true,
      },
    });

    if (roster.status !== 'matched' || roster.matchedUserId !== user.id) {
      await this.roster.markMatched(roster.id, user.id);
    }

    return user;
  }

  async listCoaches(gymId: string) {
    const staff = await this.prisma.gymStaff.findMany({
      where: {
        gymId,
        role: { in: ['coach', 'admin'] },
        authProviderId: { not: null },
      },
      select: {
        id: true,
        role: true,
        email: true,
        authProviderId: true,
      },
      orderBy: [{ role: 'asc' }, { email: 'asc' }],
    });

    const authIds = staff
      .map((s) => s.authProviderId)
      .filter((id): id is string => !!id);

    const users = await this.prisma.user.findMany({
      where: { gymId, authProviderId: { in: authIds } },
      select: {
        id: true,
        displayName: true,
        email: true,
        authProviderId: true,
      },
    });

    const byAuth = new Map(users.map((u) => [u.authProviderId!, u]));
    const userIds = users.map((u) => u.id);

    const [programCounts, activeSessions] = await Promise.all([
      userIds.length
        ? this.prisma.workoutTemplate.groupBy({
            by: ['createdByUserId'],
            where: {
              gymId,
              source: 'coach_program',
              isActive: true,
              createdByUserId: { in: userIds },
            },
            _count: { _all: true },
          })
        : Promise.resolve([]),
      userIds.length
        ? this.prisma.workoutSession.findMany({
            where: {
              gymId,
              endedAt: null,
              deletedAt: null,
              OR: [
                { userId: { in: userIds } },
                { participants: { some: { userId: { in: userIds } } } },
              ],
            },
            select: {
              userId: true,
              participants: { select: { userId: true } },
            },
          })
        : Promise.resolve([]),
    ]);

    const programsByCoach = new Map(
      programCounts.map((row) => [
        row.createdByUserId!,
        row._count._all,
      ]),
    );
    const trainingIds = new Set<string>();
    for (const session of activeSessions) {
      trainingIds.add(session.userId);
      for (const p of session.participants) trainingIds.add(p.userId);
    }

    return staff
      .map((s) => {
        const user = s.authProviderId ? byAuth.get(s.authProviderId) : undefined;
        if (!user) return null;
        return {
          userId: user.id,
          staffId: s.id,
          displayName: user.displayName || user.email || s.email,
          email: user.email ?? s.email,
          role: s.role,
          avatarUrl: null as string | null,
          programCount: programsByCoach.get(user.id) ?? 0,
          isTrainingNow: trainingIds.has(user.id),
        };
      })
      .filter((row): row is NonNullable<typeof row> => row !== null);
  }

  async listStaff(gymId: string) {
    return this.prisma.gymStaff.findMany({
      where: { gymId },
      select: {
        id: true,
        gymId: true,
        email: true,
        role: true,
        authProviderId: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: [{ role: 'asc' }, { email: 'asc' }],
    });
  }

  async updateStaffRole(gymId: string, staffId: string, dto: UpdateStaffRoleDto) {
    const staff = await this.prisma.gymStaff.findFirst({
      where: { id: staffId, gymId },
      select: { id: true, authProviderId: true },
    });
    if (!staff) {
      throw new NotFoundException('Staff account not found');
    }

    if (staff.authProviderId) {
      const existing = await this.supabase.getUserById(staff.authProviderId);
      await this.supabase.updateUserMetadata(staff.authProviderId, {
        ...(existing?.user_metadata ?? {}),
        role: dto.role,
      });
    }

    return this.prisma.gymStaff.update({
      where: { id: staffId },
      data: { role: dto.role },
      select: {
        id: true,
        gymId: true,
        email: true,
        role: true,
        authProviderId: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async sendMemberPasswordReset(gymId: string, memberId: string) {
    const member = await this.prisma.user.findFirst({
      where: { id: memberId, gymId },
      select: { email: true },
    });
    if (!member?.email) {
      throw new NotFoundException('Member email not found');
    }

    await this.supabase.sendPasswordReset(member.email);
    return { sent: true };
  }
}
