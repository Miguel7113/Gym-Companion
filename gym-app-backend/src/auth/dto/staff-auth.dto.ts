import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class StaffLoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}

export class StaffInviteDto {
  @IsString()
  @IsNotEmpty()
  gymId!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  role?: string;
}
