import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class SubmitGymApplicationDto {
  @IsString()
  @MinLength(2)
  gymName: string;

  @IsString()
  @MinLength(2)
  contactName: string;

  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  message?: string;
}
