import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NoticesController } from './notices.controller';
import { StaffNoticesController } from './staff-notices.controller';
import { NoticesService } from './notices.service';

@Module({
  imports: [AuthModule],
  controllers: [NoticesController, StaffNoticesController],
  providers: [NoticesService],
  exports: [NoticesService],
})
export class NoticesModule {}
