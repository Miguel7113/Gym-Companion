import { Module, forwardRef } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { RosterModule } from '../roster/roster.module';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import { StaffAuthGuard } from './staff-auth.guard';

@Module({
  imports: [forwardRef(() => RosterModule)],
  controllers: [AuthController],
  providers: [AuthService, SupabaseAuthGuard, StaffAuthGuard],
  exports: [AuthService, SupabaseAuthGuard, StaffAuthGuard],
})
export class AuthModule {}
