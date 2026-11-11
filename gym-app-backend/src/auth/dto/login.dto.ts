import { IsEmail, IsString, IsUUID, MinLength } from 'class-validator';

export class LoginDto {
  @IsUUID()
  gymId!: string;

  @IsEmail()
  email!: string;

  @IsString()
  // Staff passwords can be 6+ characters (StaffInviteDto).
  @MinLength(6)
  password!: string;
}
