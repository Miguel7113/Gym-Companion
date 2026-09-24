import { Module } from '@nestjs/common';
import { BuddiesController } from './buddies.controller';
import { BuddiesService } from './buddies.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [BuddiesController],
  providers: [BuddiesService],
  exports: [BuddiesService],
})
export class BuddiesModule {}
