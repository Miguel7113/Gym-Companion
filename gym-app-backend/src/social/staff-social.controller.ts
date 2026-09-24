import {
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import type { StaffContext } from '../auth/decorators/current-user.decorator';
import { SocialService } from './social.service';

@Controller('staff/social')
@UseGuards(StaffAuthGuard)
export class StaffSocialController {
  constructor(private readonly socialService: SocialService) {}

  @Get('flagged')
  listFlagged(@CurrentStaff() staff: StaffContext) {
    return this.socialService.listFlaggedPosts(staff.gymId);
  }

  @Get('recent')
  listRecent(
    @CurrentStaff() staff: StaffContext,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.listRecentPostsForStaff(
      staff.gymId,
      limit ? Number(limit) : undefined,
    );
  }

  @Post('posts/:id/dismiss-flag')
  dismissFlag(
    @CurrentStaff() staff: StaffContext,
    @Param('id') postId: string,
  ) {
    return this.socialService.dismissFlaggedPost(staff.gymId, postId);
  }

  @Delete('posts/:id')
  softDeletePost(
    @CurrentStaff() staff: StaffContext,
    @Param('id') postId: string,
  ) {
    return this.socialService.softDeletePostAsStaff(staff.gymId, postId);
  }
}
