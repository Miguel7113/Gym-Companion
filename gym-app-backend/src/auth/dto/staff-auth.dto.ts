import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class StaffLoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}

export class StaffInviteDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsOptional()
  @IsString()
  @IsIn(['admin', 'coach'])
  role?: string;
}

export class UpdateStaffRoleDto {
  @IsString()
  @IsIn(['admin', 'coach'])
  role!: string;
}
