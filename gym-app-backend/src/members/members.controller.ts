import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { MembersService } from './members.service';

@Controller('members')
@UseGuards(SupabaseAuthGuard)
export class MembersController {
  constructor(private readonly membersService: MembersService) {}

  /** Gym floor directory — peers only (coaches excluded), with buddy + training flags. */
  @Get('directory')
  listDirectory(
    @CurrentMember() viewer: { userId: string; gymId: string },
    @Query('q') q?: string,
  ) {
    return this.membersService.listDirectory(viewer.userId, viewer.gymId, q);
  }

  @Get(':memberId/profile')
  getProfile(
    @CurrentMember() viewer: { userId: string; gymId: string },
    @Param('memberId') memberId: string,
    @Query('postsLimit') postsLimit?: string,
    @Query('postsOffset') postsOffset?: string,
  ) {
    return this.membersService.getProfile(
      viewer.userId,
      viewer.gymId,
      memberId,
      postsLimit ? parseInt(postsLimit, 10) : 20,
      postsOffset ? parseInt(postsOffset, 10) : 0,
    );
  }
}
