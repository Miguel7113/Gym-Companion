import { Module } from '@nestjs/common';
import { GymApplicationsController } from './gym-applications.controller';
import { GymApplicationsService } from './gym-applications.service';

@Module({
  controllers: [GymApplicationsController],
  providers: [GymApplicationsService],
})
export class GymApplicationsModule {}
