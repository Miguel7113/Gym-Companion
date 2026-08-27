import { Module, forwardRef } from '@nestjs/common';
import { RosterController } from './roster.controller';
import { RosterService } from './roster.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [forwardRef(() => AuthModule)],
  controllers: [RosterController],
  providers: [RosterService],
  exports: [RosterService],
})
export class RosterModule {}
