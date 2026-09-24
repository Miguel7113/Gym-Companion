import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { GymsService } from './gyms.service';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import { UpdateGymSettingsDto } from './dto/update-gym-settings.dto';
import {
  GymDashboardService,
  parseDashboardRange,
} from './gym-dashboard.service';

@Controller('gyms')
export class GymsController {
  constructor(
    private gymsService: GymsService,
    private dashboardService: GymDashboardService,
  ) {}

  @Get()
  listActive() {
    return this.gymsService.listActive();
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.gymsService.getById(id);
  }

  @UseGuards(StaffAuthGuard)
  @Get(':id/stats')
  getStats(@Param('id') id: string, @CurrentStaff() staff: { gymId: string }) {
    if (staff.gymId !== id) {
      throw new ForbiddenException('Staff access is limited to their gym');
    }
    return this.gymsService.getStats(id);
  }

  @UseGuards(StaffAuthGuard)
  @Get(':id/dashboard')
  getDashboard(
    @Param('id') id: string,
    @CurrentStaff() staff: { gymId: string },
    @Query('range') range?: string,
  ) {
    if (staff.gymId !== id) {
      throw new ForbiddenException('Staff access is limited to their gym');
    }
    return this.dashboardService.getDashboard(id, parseDashboardRange(range));
  }

  @UseGuards(StaffAuthGuard)
  @Get(':id/members')
  listMembers(
    @Param('id') id: string,
    @CurrentStaff() staff: { gymId: string },
    @Query('q') q?: string,
  ) {
    if (staff.gymId !== id) {
      throw new ForbiddenException('Staff access is limited to their gym');
    }
    return this.gymsService.listMembers(id, q);
  }

  @UseGuards(StaffAuthGuard)
  @Get(':id/settings')
  getSettings(
    @Param('id') id: string,
    @CurrentStaff() staff: { gymId: string },
  ) {
    if (staff.gymId !== id) {
      throw new ForbiddenException('Staff access is limited to their gym');
    }
    return this.gymsService.getSettings(id);
  }

  @UseGuards(StaffAuthGuard)
  @Patch(':id/settings')
  updateSettings(
    @Param('id') id: string,
    @CurrentStaff() staff: { gymId: string },
    @Body() dto: UpdateGymSettingsDto,
  ) {
    if (staff.gymId !== id) {
      throw new ForbiddenException('Staff access is limited to their gym');
    }
    return this.gymsService.updateSettings(id, dto);
  }
}
