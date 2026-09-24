import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
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
import { StaffAuthGuard } from './staff-auth.guard';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import {
  CurrentStaff,
  CurrentMember,
  type StaffContext,
} from './decorators/current-user.decorator';

const LOGIN_LIMIT = { default: { limit: 20, ttl: 60_000 } };
const EMAIL_LIMIT = { default: { limit: 10, ttl: 60_000 } };

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  // ── Pre-check: is this email on the gym roster? ────────────────────────────
  // Called before showing any auth form. Returns:
  //   { exists: false }                    → not a member → show error, stop
  //   { exists: true, hasPassword: false } → new member → proceed with OTP
  //   { exists: true, hasPassword: true }  → returning → show LoginScreen
  @Throttle(LOGIN_LIMIT)
  @Post('check-member')
  checkMember(@Body() dto: CheckMemberDto) {
    return this.authService.checkMember(dto);
  }

  // ── Day-to-day password login ──────────────────────────────────────────────
  @Throttle(LOGIN_LIMIT)
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // ── Set password (called once after first OTP/magic link verification) ─────
  @Throttle(LOGIN_LIMIT)
  @Post('set-password')
  setPassword(
    @Headers('authorization') authHeader: string,
    @Body() dto: SetPasswordDto,
  ) {
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing Bearer token');
    }
    const accessToken = authHeader.slice(7);
    // We need the auth user ID — verify the token first
    return this.authService.setPasswordFromToken(accessToken, dto);
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  @Throttle(EMAIL_LIMIT)
  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Throttle(EMAIL_LIMIT)
  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto);
  }

  @Throttle(LOGIN_LIMIT)
  @Post('verify-otp')
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  // ── Magic link claim ───────────────────────────────────────────────────────
  @Post('claim-session')
  claimSession(
    @Headers('authorization') authHeader: string,
    @Body() dto: ClaimSessionDto,
  ) {
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing Bearer token');
    }
    const accessToken = authHeader.slice(7);
    return this.authService.claimSession(accessToken, dto);
  }

  @Throttle(LOGIN_LIMIT)
  @Post('staff/login')
  staffLogin(@Body() dto: StaffLoginDto) {
    return this.authService.staffLogin(dto);
  }

  /** Flutter coach/admin login — member JWT with staff role claims. */
  @Throttle(LOGIN_LIMIT)
  @Post('coach/login')
  coachLogin(@Body() dto: StaffLoginDto) {
    return this.authService.coachLogin(dto);
  }

  @UseGuards(SupabaseAuthGuard)
  @Get('coaches')
  listCoaches(@CurrentMember() member: { gymId: string }) {
    return this.authService.listCoaches(member.gymId);
  }

  @UseGuards(StaffAuthGuard)
  @Post('staff/invite')
  staffInvite(
    @CurrentStaff() staff: StaffContext,
    @Body() dto: StaffInviteDto,
  ) {
    if (staff.role.toLowerCase() !== 'admin') {
      throw new ForbiddenException('Only admins can invite staff');
    }
    return this.authService.staffInvite(staff.gymId, dto);
  }

  @UseGuards(StaffAuthGuard)
  @Get('staff')
  listStaff(@CurrentStaff() staff: StaffContext) {
    return this.authService.listStaff(staff.gymId);
  }

  @UseGuards(StaffAuthGuard)
  @Patch('staff/:staffId')
  updateStaffRole(
    @CurrentStaff() staff: StaffContext,
    @Param('staffId') staffId: string,
    @Body() dto: UpdateStaffRoleDto,
  ) {
    if (staff.role.toLowerCase() !== 'admin') {
      throw new ForbiddenException('Only admins can manage staff roles');
    }
    return this.authService.updateStaffRole(staff.gymId, staffId, dto);
  }

  @UseGuards(StaffAuthGuard)
  @Post('staff/members/:memberId/reset-password')
  sendMemberPasswordReset(
    @CurrentStaff() staff: StaffContext,
    @Param('memberId') memberId: string,
  ) {
    return this.authService.sendMemberPasswordReset(staff.gymId, memberId);
  }
}
