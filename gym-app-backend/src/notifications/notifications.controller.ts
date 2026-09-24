import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(SupabaseAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  list(
    @CurrentMember() member: { userId: string; gymId: string },
    @Query('limit') limit?: string,
  ) {
    return this.notificationsService.list(
      member.userId,
      member.gymId,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Post(':id/read')
  markRead(
    @CurrentMember() member: { userId: string },
    @Param('id') id: string,
  ) {
    return this.notificationsService.markRead(member.userId, id);
  }

  @Post('read-all')
  markAllRead(@CurrentMember() member: { userId: string; gymId: string }) {
    return this.notificationsService.markAllRead(member.userId, member.gymId);
  }
}
