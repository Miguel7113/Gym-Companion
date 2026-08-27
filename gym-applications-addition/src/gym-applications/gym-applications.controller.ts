import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { GymApplicationsService } from './gym-applications.service';
import { SubmitGymApplicationDto } from './dto/submit-application.dto';
import { AdminKeyGuard } from './admin-key.guard';

@Controller('gym-applications')
export class GymApplicationsController {
  constructor(private gymApplicationsService: GymApplicationsService) {}

  // Public — the marketing site's "Apply to join" form calls this directly,
  // no auth required.
  @Post()
  submit(@Body() dto: SubmitGymApplicationDto) {
    return this.gymApplicationsService.submit(dto);
  }

  @UseGuards(AdminKeyGuard)
  @Get('pending')
  listPending() {
    return this.gymApplicationsService.listPending();
  }

  @UseGuards(AdminKeyGuard)
  @Post(':id/approve')
  approve(@Param('id') id: string) {
    return this.gymApplicationsService.approve(id);
  }

  @UseGuards(AdminKeyGuard)
  @Post(':id/reject')
  reject(@Param('id') id: string) {
    return this.gymApplicationsService.reject(id);
  }
}
