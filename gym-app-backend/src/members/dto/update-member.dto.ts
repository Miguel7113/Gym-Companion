import { IsEmail, IsIn, IsNumber, IsOptional, IsString, MaxLength, Min, Max } from 'class-validator';

export class UpdateMemberDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  displayName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  subscriptionTier?: string;

  @IsOptional()
  @IsString()
  @IsIn(['male', 'female', 'other'])
  gender?: string;

  @IsOptional()
  @IsNumber()
  @Min(30)
  @Max(300)
  bodyWeightKg?: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  bio?: string;
}
