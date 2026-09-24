import { IsOptional, IsUUID } from 'class-validator';

export class BuddyRequestDto {
  @IsUUID()
  toUserId!: string;
}

export class StartBuddySessionDto {
  @IsUUID()
  buddyUserId!: string;

  @IsOptional()
  @IsUUID()
  templateId?: string;
}
