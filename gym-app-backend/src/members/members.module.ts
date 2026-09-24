import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SocialModule } from '../social/social.module';
import { MembersController } from './members.controller';
import { MembersService } from './members.service';
import { StaffMembersController } from './staff-members.controller';

@Module({
  imports: [AuthModule, SocialModule],
  controllers: [MembersController, StaffMembersController],
  providers: [MembersService],
})
export class MembersModule {}
