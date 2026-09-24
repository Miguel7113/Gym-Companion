import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreatePostDto {
  // Staff announcements: 'announcement' | 'class_update' | 'reminder'
  // Achievement posts are auto-generated — not created via this endpoint
  @IsIn(['announcement', 'class_update', 'reminder'])
  type!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  content!: string;

  // imageUrl: optional for staff posts; auto-set for achievement posts
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class ShareWorkoutDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  content?: string;

  /** Supabase Storage object path, never a public URL. */
  @IsOptional()
  @IsString()
  @MaxLength(500)
  imagePath?: string;
}

export class CreateCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  content!: string;
}
