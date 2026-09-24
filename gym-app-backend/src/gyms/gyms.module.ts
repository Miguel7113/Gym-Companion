import { Module } from '@nestjs/common';
import { GymsController } from './gyms.controller';
import { GymsService } from './gyms.service';
import { GymDashboardService } from './gym-dashboard.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [GymsController],
  providers: [GymsService, GymDashboardService],
  exports: [GymsService],
})
export class GymsModule {}
