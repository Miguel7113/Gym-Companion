import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import { StaffSocialController } from './staff-social.controller';
import { SocialService } from './social.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [SocialController, StaffSocialController],
  providers: [SocialService],
  exports: [SocialService],
})
export class SocialModule {}
