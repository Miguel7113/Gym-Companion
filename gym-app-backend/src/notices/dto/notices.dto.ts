import {
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Allowed notice tags (v1). */
export const NOTICE_TAGS = [
  'ANNOUNCEMENT',
  'CLASS_UPDATE',
  'REMINDER',
  'EVENT',
] as const;

export type NoticeTag = (typeof NOTICE_TAGS)[number];

export class CreateNoticeDto {
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  body!: string;

  @IsIn([...NOTICE_TAGS])
  tag!: NoticeTag;

  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;
}

export class UpdateNoticeDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  body?: string;

  @IsOptional()
  @IsIn([...NOTICE_TAGS])
  tag?: NoticeTag;

  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;
}
