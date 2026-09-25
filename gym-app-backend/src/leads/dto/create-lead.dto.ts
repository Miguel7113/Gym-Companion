import {
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export const MEMBER_COUNT_BANDS = ['UNDER_100', '100_300', 'OVER_300'] as const;

export class CreateLeadDto {
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  gymName!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  contactName!: string;

  @IsEmail()
  @MaxLength(200)
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  city?: string;

  @IsOptional()
  @IsIn([...MEMBER_COUNT_BANDS])
  memberCount?: (typeof MEMBER_COUNT_BANDS)[number];

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  message?: string;

  // Honeypot: real users never see this field.
  @IsOptional()
  @IsString()
  @MaxLength(200)
  website?: string;
}
