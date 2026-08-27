import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { SupabaseModule } from './supabase/supabase.module';
import { AuthModule } from './auth/auth.module';
import { RosterModule } from './roster/roster.module';
import { GymsModule } from './gyms/gyms.module';
import { WorkoutsModule } from './workouts/workouts.module';
import { SocialModule } from './social/social.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    SupabaseModule,
    AuthModule,
    RosterModule,
    GymsModule,
    WorkoutsModule,
    SocialModule,
  ],
})
export class AppModule {}
