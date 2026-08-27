import { IsEmail, IsUUID } from 'class-validator';

export class ForgotPasswordDto {
  @IsUUID()
  gymId!: string;

  @IsEmail()
  email!: string;
}
