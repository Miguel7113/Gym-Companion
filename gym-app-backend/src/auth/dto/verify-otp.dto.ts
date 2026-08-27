import { IsEmail, IsOptional, IsString, IsUUID, ValidateIf } from 'class-validator';

export class VerifyOtpDto {
  @IsUUID()
  gymId!: string;

  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  @IsString()
  token!: string;

  @IsOptional()
  @IsString()
  displayName?: string;
}
