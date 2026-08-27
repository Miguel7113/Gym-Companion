import { Body, Controller, Headers, Post, UnauthorizedException, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { ClaimSessionDto } from './dto/claim-session.dto';
import { CheckMemberDto } from './dto/check-member.dto';
import { LoginDto } from './dto/login.dto';
import { SetPasswordDto } from './dto/set-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { StaffInviteDto, StaffLoginDto } from './dto/staff-auth.dto';
import { StaffAuthGuard } from './staff-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  // ── Pre-check: is this email on the gym roster? ────────────────────────────
  // Called before showing any auth form. Returns:
  //   { exists: false }                    → not a member → show error, stop
  //   { exists: true, hasPassword: false } → new member → proceed with OTP
  //   { exists: true, hasPassword: true }  → returning → show LoginScreen
  @Post('check-member')
  checkMember(@Body() dto: CheckMemberDto) {
    return this.authService.checkMember(dto);
  }

  // ── Day-to-day password login ──────────────────────────────────────────────
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // ── Set password (called once after first OTP/magic link verification) ─────
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
  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto);
  }

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

  @Post('staff/login')
  staffLogin(@Body() dto: StaffLoginDto) {
    return this.authService.staffLogin(dto);
  }

  @UseGuards(StaffAuthGuard)
  @Post('staff/invite')
  staffInvite(@Body() dto: StaffInviteDto) {
    return this.authService.staffInvite(dto);
  }
}
