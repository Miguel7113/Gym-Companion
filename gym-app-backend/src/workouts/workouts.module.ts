import { Module, forwardRef } from '@nestjs/common';
import { WorkoutsController } from './workouts.controller';
import { WorkoutsService } from './workouts.service';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { BuddiesModule } from '../buddies/buddies.module';

@Module({
  imports: [AuthModule, NotificationsModule, forwardRef(() => BuddiesModule)],
  controllers: [WorkoutsController],
  providers: [WorkoutsService],
  exports: [WorkoutsService],
})
export class WorkoutsModule {}
