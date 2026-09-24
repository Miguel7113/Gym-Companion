import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import { MembersService } from './members.service';
import { UpdateMemberDto } from './dto/update-member.dto';

@Controller('staff/members')
@UseGuards(StaffAuthGuard)
export class StaffMembersController {
  constructor(private readonly membersService: MembersService) {}

  @Get(':memberId/profile')
  getProfile(
    @CurrentStaff() staff: { staffId: string; gymId: string },
    @Param('memberId') memberId: string,
    @Query('postsLimit') postsLimit?: string,
    @Query('postsOffset') postsOffset?: string,
  ) {
    return this.membersService.getProfile(
      `staff:${staff.staffId}`,
      staff.gymId,
      memberId,
      postsLimit ? parseInt(postsLimit, 10) : 20,
      postsOffset ? parseInt(postsOffset, 10) : 0,
      { includeContact: true },
    );
  }

  @Patch(':memberId')
  updateMember(
    @CurrentStaff() staff: { gymId: string },
    @Param('memberId') memberId: string,
    @Body() dto: UpdateMemberDto,
  ) {
    return this.membersService.updateMember(staff.gymId, memberId, dto);
  }
}
