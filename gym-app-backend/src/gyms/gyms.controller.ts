import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { GymsService } from './gyms.service';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';

@Controller('gyms')
export class GymsController {
  constructor(private gymsService: GymsService) {}

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
      return this.gymsService.getStats(id);
    }
    return this.gymsService.getStats(id);
  }

  @UseGuards(StaffAuthGuard)
  @Get(':id/members')
  listMembers(@Param('id') id: string) {
    return this.gymsService.listMembers(id);
  }
}
