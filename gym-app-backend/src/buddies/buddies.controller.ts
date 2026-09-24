import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { BuddiesService } from './buddies.service';
import { BuddyRequestDto } from './dto/buddies.dto';

@Controller('buddies')
@UseGuards(SupabaseAuthGuard)
export class BuddiesController {
  constructor(private readonly buddiesService: BuddiesService) {}

  @Get()
  list(@CurrentMember() member: { userId: string; gymId: string }) {
    return this.buddiesService.list(member.userId, member.gymId);
  }

  @Get('search')
  search(
    @CurrentMember() member: { userId: string; gymId: string },
    @Query('q') q?: string,
  ) {
    return this.buddiesService.searchMembers(member.userId, member.gymId, q);
  }

  @Post('request')
  request(
    @CurrentMember() member: { userId: string; gymId: string },
    @Body() dto: BuddyRequestDto,
  ) {
    return this.buddiesService.request(member.userId, member.gymId, dto.toUserId);
  }

  @Post(':id/accept')
  accept(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.buddiesService.accept(member.userId, member.gymId, id);
  }

  @Post(':id/decline')
  decline(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.buddiesService.decline(member.userId, member.gymId, id);
  }

  @Post(':id/cancel')
  cancel(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.buddiesService.cancel(member.userId, member.gymId, id);
  }
}
