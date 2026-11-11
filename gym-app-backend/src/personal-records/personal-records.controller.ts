import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PersonalRecordsService } from './personal-records.service';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';

@Controller('personal-records')
@UseGuards(SupabaseAuthGuard)
export class PersonalRecordsController {
  constructor(private readonly prService: PersonalRecordsService) {}

  /**
   * Get own PRs (includes unverified)
   */
  @Get('my-prs')
  async getMyPRs(@Request() req: any, @Query('gymId') gymId: string) {
    return this.prService.getUserPRs(req.user.sub, gymId);
  }

  /**
   * Get user's verified PRs (public view)
   */
  @Get('user/:userId')
  async getUserPRs(
    @Param('userId') userId: string,
    @Query('gymId') gymId: string,
  ) {
    return this.prService.getUserVerifiedPRs(userId, gymId);
  }

  /**
   * Create or update a PR
   */
  @Post()
  async upsertPR(
    @Request() req: any,
    @Body()
    body: {
      gymId: string;
      exerciseName: string;
      weightKg?: number;
      reps: number;
      achievedDate: string;
    },
  ) {
    return this.prService.upsertPR({
      userId: req.user.sub,
      gymId: body.gymId,
      exerciseName: body.exerciseName,
      weightKg: body.weightKg,
      reps: body.reps,
      achievedDate: new Date(body.achievedDate),
    });
  }

  /**
   * Delete own unverified PR
   */
  @Delete(':prId')
  async deletePR(@Param('prId') prId: string, @Request() req: any) {
    return this.prService.deletePR(prId, req.user.sub);
  }

  /**
   * Get pending PRs (coach only)
   */
  @Get('coach/pending')
  async getPendingPRs(@Request() req: any) {
    return this.prService.getPendingPRsForCoach(req.user.sub);
  }

  /**
   * Get coach dashboard statistics (coach only)
   */
  @Get('coach/stats')
  async getCoachStats(@Request() req: any) {
    return this.prService.getCoachStats(req.user.sub);
  }

  /**
   * Verify a PR (coach only)
   */
  @Post('coach/verify/:prId')
  async verifyPR(@Param('prId') prId: string, @Request() req: any) {
    return this.prService.verifyPR(prId, req.user.sub);
  }

  /**
   * Reject a PR (coach only)
   */
  @Post('coach/reject/:prId')
  async rejectPR(
    @Param('prId') prId: string,
    @Request() req: any,
    @Body() body: { reason?: string },
  ) {
    return this.prService.rejectPR(prId, req.user.sub, body.reason);
  }

  /**
   * Get leaderboard for an exercise
   */
  @Get('leaderboard/:exercise')
  async getLeaderboard(
    @Param('exercise') exercise: 'Bench Press' | 'Squat' | 'Deadlift',
    @Query('gymId') gymId: string,
    @Query('gender') gender?: 'male' | 'female' | 'other',
    @Query('limit') limit?: string,
  ) {
    return this.prService.getLeaderboard({
      gymId,
      exercise,
      gender,
      limit: limit ? parseInt(limit, 10) : 10,
    });
  }

  /**
   * Get user's rank in an exercise
   */
  @Get('leaderboard/:exercise/rank')
  async getUserRank(
    @Param('exercise') exercise: 'Bench Press' | 'Squat' | 'Deadlift',
    @Query('gymId') gymId: string,
    @Query('userId') userId: string,
    @Query('gender') gender?: 'male' | 'female' | 'other',
  ) {
    return this.prService.getUserRank({
      userId,
      gymId,
      exercise,
      gender,
    });
  }
}
