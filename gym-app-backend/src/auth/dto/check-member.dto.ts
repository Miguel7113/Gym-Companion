import { IsEmail, IsOptional, IsString, IsUUID, ValidateIf } from 'class-validator';

export class CheckMemberDto {
  @IsUUID()
  gymId!: string;

  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;
}
