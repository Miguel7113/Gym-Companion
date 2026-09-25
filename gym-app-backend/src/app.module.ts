import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { validateEnv } from './config/env.validation';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { SupabaseModule } from './supabase/supabase.module';
import { AuthModule } from './auth/auth.module';
import { RosterModule } from './roster/roster.module';
import { GymsModule } from './gyms/gyms.module';
import { WorkoutsModule } from './workouts/workouts.module';
import { SocialModule } from './social/social.module';
import { MembersModule } from './members/members.module';
import { NoticesModule } from './notices/notices.module';
import { BuddiesModule } from './buddies/buddies.module';
import { NotificationsModule } from './notifications/notifications.module';
import { LeadsModule } from './leads/leads.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    // Members often share one gym Wi-Fi IP, so the global limit is generous;
    // auth routes set tighter per-route limits.
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 600 }]),
    HealthModule,
    PrismaModule,
    SupabaseModule,
    AuthModule,
    RosterModule,
    GymsModule,
    WorkoutsModule,
    SocialModule,
    MembersModule,
    NoticesModule,
    BuddiesModule,
    NotificationsModule,
    LeadsModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
