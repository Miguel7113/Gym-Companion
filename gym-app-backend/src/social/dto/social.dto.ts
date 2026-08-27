import { IsOptional, IsString, IsIn } from 'class-validator';

export class CreatePostDto {
  // Staff announcements: 'announcement' | 'class_update' | 'reminder'
  // Achievement posts are auto-generated — not created via this endpoint
  @IsIn(['announcement', 'class_update', 'reminder'])
  type!: string;

  @IsString()
  content!: string;

  // imageUrl: optional for staff posts; auto-set for achievement posts
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreateCommentDto {
  @IsString()
  content!: string;
}
