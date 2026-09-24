import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import type { MemberContext } from '../auth/decorators/current-user.decorator';
import { CreateNoticeDto, UpdateNoticeDto } from './dto/notices.dto';
import { NoticesService } from './notices.service';

/**
 * Member + coach (app) notices API.
 * Notices appear on Home / Notices — never in the social feed.
 */
@Controller('notices')
@UseGuards(SupabaseAuthGuard)
export class NoticesController {
  constructor(private noticesService: NoticesService) {}

  @Get()
  list(
    @CurrentMember() member: MemberContext,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.noticesService.listForMembers(
      member.gymId,
      limit ? parseInt(limit, 10) : 50,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  @Get(':id')
  getOne(
    @CurrentMember() member: MemberContext,
    @Param('id') id: string,
  ) {
    return this.noticesService.getForMember(member.gymId, id);
  }

  @Post()
  async create(
    @CurrentMember() member: MemberContext,
    @Body() dto: CreateNoticeDto,
  ) {
    this.requireCoach(member);
    const staffId = await this.noticesService.findStaffIdForAuth(
      member.gymId,
      member.authProviderId,
    );
    return this.noticesService.createAsCoach(
      member.gymId,
      member.userId,
      staffId,
      dto,
    );
  }

  @Patch(':id')
  update(
    @CurrentMember() member: MemberContext,
    @Param('id') id: string,
    @Body() dto: UpdateNoticeDto,
  ) {
    this.requireCoach(member);
    return this.noticesService.update(member.gymId, id, dto);
  }

  @Delete(':id')
  softDelete(
    @CurrentMember() member: MemberContext,
    @Param('id') id: string,
  ) {
    this.requireCoach(member);
    return this.noticesService.softDelete(member.gymId, id);
  }

  @Post(':id/restore')
  restore(
    @CurrentMember() member: MemberContext,
    @Param('id') id: string,
  ) {
    this.requireCoach(member);
    return this.noticesService.restore(member.gymId, id);
  }

  /** Coaches (and any gym_staff linked to the member) may manage notices in-app. */
  private requireCoach(member: MemberContext) {
    if (!member.isStaff) {
      throw new ForbiddenException('Only coaches can manage notices');
    }
  }
}
