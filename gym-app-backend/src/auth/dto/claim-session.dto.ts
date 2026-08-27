import { IsEmail, IsOptional, IsString, ValidateIf } from 'class-validator';

export class ClaimSessionDto {
  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  // The Supabase refresh token from the magic link session.
  // We need it to call refreshSession() after injecting JWT metadata.
  @IsString()
  refreshToken!: string;

  // Optional: display name captured during onboarding, used as fallback
  // if the roster entry has no memberName set yet.
  @IsOptional()
  @IsString()
  displayName?: string;
}
