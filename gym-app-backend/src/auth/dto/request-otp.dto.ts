import { IsEmail, IsOptional, IsString, IsUUID, ValidateIf } from 'class-validator';

export class RequestOtpDto {
  @IsUUID()
  gymId!: string;

  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  /** Only used if there's no roster match — lets us create a pending request. */
  @IsOptional()
  @IsString()
  displayName?: string;
}
