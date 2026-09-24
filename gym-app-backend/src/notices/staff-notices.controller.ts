import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import type { StaffContext } from '../auth/decorators/current-user.decorator';
import { CreateNoticeDto, UpdateNoticeDto } from './dto/notices.dto';
import { NoticesService } from './notices.service';

/**
 * Admin portal notices API (website).
 * Uses gym_staff auth — separate from member/coach app JWT path.
 */
@Controller('staff/notices')
@UseGuards(StaffAuthGuard)
export class StaffNoticesController {
  constructor(private noticesService: NoticesService) {}

  @Get()
  list(
    @CurrentStaff() staff: StaffContext,
    @Query('includeDeleted') includeDeleted?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.noticesService.listForStaff(staff.gymId, {
      includeDeleted: includeDeleted === 'true' || includeDeleted === '1',
      limit: limit ? parseInt(limit, 10) : 50,
      offset: offset ? parseInt(offset, 10) : 0,
    });
  }

  @Post()
  create(
    @CurrentStaff() staff: StaffContext,
    @Body() dto: CreateNoticeDto,
  ) {
    return this.noticesService.createAsStaff(staff.gymId, staff.staffId, dto);
  }

  @Patch(':id')
  update(
    @CurrentStaff() staff: StaffContext,
    @Param('id') id: string,
    @Body() dto: UpdateNoticeDto,
  ) {
    return this.noticesService.update(staff.gymId, id, dto);
  }

  @Delete(':id')
  softDelete(
    @CurrentStaff() staff: StaffContext,
    @Param('id') id: string,
  ) {
    return this.noticesService.softDelete(staff.gymId, id);
  }

  @Post(':id/restore')
  restore(
    @CurrentStaff() staff: StaffContext,
    @Param('id') id: string,
  ) {
    return this.noticesService.restore(staff.gymId, id);
  }
}
