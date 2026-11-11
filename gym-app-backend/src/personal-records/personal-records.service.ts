import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class PersonalRecordsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  /**
   * Get user's PRs (own view - includes unverified)
   */
  async getUserPRs(userId: string, gymId: string) {
    return this.prisma.personalRecord.findMany({
      where: { userId, gymId },
      orderBy: [
        { status: 'desc' }, // verified first
        { exerciseName: 'asc' },
      ],
    });
  }

  /**
   * Get user's verified PRs (public view)
   */
  async getUserVerifiedPRs(userId: string, gymId: string) {
    return this.prisma.personalRecord.findMany({
      where: {
        userId,
        gymId,
        status: 'verified',
      },
      orderBy: { exerciseName: 'asc' },
      take: 5, // Top 5 verified PRs
    });
  }

  /**
   * Create or update a PR
   */
  async upsertPR(params: {
    userId: string;
    gymId: string;
    exerciseName: string;
    weightKg?: number;
    reps: number;
    achievedDate: Date;
  }) {
    const { userId, gymId, exerciseName, weightKg, reps, achievedDate } = params;

    // Check if PR already exists
    const existing = await this.prisma.personalRecord.findUnique({
      where: {
        gymId_userId_exerciseName: { gymId, userId, exerciseName },
      },
    });

    // ⚠️ NEW RATE LIMIT: 1 submission per day per exercise
    // Prevents notification spam to coaches
    if (existing) {
      const hoursSinceLastSubmission =
        (Date.now() - existing.lastSubmissionAt.getTime()) / (1000 * 60 * 60);

      if (hoursSinceLastSubmission < 24) {
        const hoursRemaining = Math.ceil(24 - hoursSinceLastSubmission);
        throw new BadRequestException(
          `You can only submit this PR once per day. Please try again in ${hoursRemaining} hour${hoursRemaining !== 1 ? 's' : ''}.`,
        );
      }
    }

    const submissionCount =
      existing && existing.status === 'rejected'
        ? existing.submissionCount + 1
        : 1;

    return this.prisma.personalRecord.upsert({
      where: {
        gymId_userId_exerciseName: { gymId, userId, exerciseName },
      },
      create: {
        id: crypto.randomUUID(),
        gymId,
        userId,
        exerciseName,
        weightKg,
        reps,
        achievedDate,
        status: 'pending',
        submissionCount,
      },
      update: {
        weightKg,
        reps,
        achievedDate,
        status: 'pending',
        submissionCount,
        lastSubmissionAt: new Date(),
        verifiedAt: null,
        verifiedByCoachId: null,
        rejectionReason: null,
      },
    });
  }

  /**
   * Delete own unverified PR
   */
  async deletePR(prId: string, userId: string) {
    const pr = await this.prisma.personalRecord.findUnique({
      where: { id: prId },
    });

    if (!pr) {
      throw new NotFoundException('Personal record not found');
    }

    if (pr.userId !== userId) {
      throw new ForbiddenException('You can only delete your own PRs');
    }

    if (pr.status !== 'pending') {
      throw new BadRequestException(
        'Cannot delete verified or rejected PRs. Contact a coach to make changes.',
      );
    }

    await this.prisma.personalRecord.delete({ where: { id: prId } });
    return { deleted: true };
  }

  /**
   * Get pending PRs for coach review
   */
  async getPendingPRsForCoach(coachUserId: string) {
    // Verify coach status
    const coachStaff = await this.prisma.gymStaff.findFirst({
      where: {
        authProviderId: coachUserId,
        role: { in: ['coach', 'admin', 'owner'] },
      },
    });

    if (!coachStaff) {
      throw new ForbiddenException('Only coaches can view pending PRs');
    }

    return this.prisma.personalRecord.findMany({
      where: {
        gymId: coachStaff.gymId,
        status: 'pending',
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarPath: true,
            gender: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Get coach dashboard statistics
   */
  async getCoachStats(coachUserId: string) {
    // Verify coach status
    const coachStaff = await this.prisma.gymStaff.findFirst({
      where: {
        authProviderId: coachUserId,
        role: { in: ['coach', 'admin', 'owner'] },
      },
    });

    if (!coachStaff) {
      throw new ForbiddenException('Only coaches can view stats');
    }

    // Find the coach's user record
    const coach = await this.prisma.user.findFirst({
      where: { authProviderId: coachUserId },
    });

    if (!coach) {
      throw new NotFoundException('Coach user not found');
    }

    const gymId = coachStaff.gymId;
    const now = new Date();
    const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    // Get pending count
    const pendingCount = await this.prisma.personalRecord.count({
      where: {
        gymId,
        status: 'pending',
      },
    });

    // Get verified today count
    const verifiedToday = await this.prisma.personalRecord.count({
      where: {
        gymId,
        status: 'verified',
        verifiedByCoachId: coach.id,
        verifiedAt: {
          gte: twentyFourHoursAgo,
        },
      },
    });

    // Calculate average response time
    const recentVerifications = await this.prisma.personalRecord.findMany({
      where: {
        gymId,
        status: { in: ['verified', 'rejected'] },
        verifiedByCoachId: coach.id,
        verifiedAt: {
          gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000), // Last 7 days
        },
      },
      select: {
        createdAt: true,
        verifiedAt: true,
      },
    });

    let avgResponseTimeHours = 0;
    if (recentVerifications.length > 0) {
      const totalHours = recentVerifications.reduce((sum, pr) => {
        if (pr.verifiedAt) {
          const hours =
            (pr.verifiedAt.getTime() - pr.createdAt.getTime()) /
            (1000 * 60 * 60);
          return sum + hours;
        }
        return sum;
      }, 0);
      avgResponseTimeHours = totalHours / recentVerifications.length;
    }

    // Get breakdown by exercise
    const byExerciseData = await this.prisma.personalRecord.groupBy({
      by: ['exerciseName'],
      where: {
        gymId,
        status: 'pending',
      },
      _count: {
        exerciseName: true,
      },
    });

    const byExercise = {
      benchPress:
        byExerciseData.find((e) => e.exerciseName === 'Bench Press')?._count
          .exerciseName || 0,
      squat:
        byExerciseData.find((e) => e.exerciseName === 'Squat')?._count
          .exerciseName || 0,
      deadlift:
        byExerciseData.find((e) => e.exerciseName === 'Deadlift')?._count
          .exerciseName || 0,
    };

    return {
      pendingCount,
      verifiedToday,
      avgResponseTimeHours: Math.round(avgResponseTimeHours * 10) / 10, // Round to 1 decimal
      byExercise,
    };
  }

  /**
   * Verify a PR (coach action)
   */
  async verifyPR(prId: string, coachUserId: string) {
    // Verify coach status
    const coachStaff = await this.prisma.gymStaff.findFirst({
      where: {
        authProviderId: coachUserId,
        role: { in: ['coach', 'admin', 'owner'] },
      },
    });

    if (!coachStaff) {
      throw new ForbiddenException('Only coaches can verify PRs');
    }

    const pr = await this.prisma.personalRecord.findUnique({
      where: { id: prId },
      include: { user: true },
    });

    if (!pr) {
      throw new NotFoundException('Personal record not found');
    }

    if (pr.gymId !== coachStaff.gymId) {
      throw new ForbiddenException('Can only verify PRs in your gym');
    }

    // Find the coach's user record
    const coach = await this.prisma.user.findFirst({
      where: { authProviderId: coachUserId },
    });

    if (!coach) {
      throw new NotFoundException('Coach user not found');
    }

    const updated = await this.prisma.personalRecord.update({
      where: { id: prId },
      data: {
        status: 'verified',
        verifiedByCoachId: coach.id,
        verifiedAt: new Date(),
        rejectionReason: null,
      },
    });

    // Send notification to user
    await this.notifications.create({
      gymId: pr.gymId,
      userId: pr.userId,
      type: 'pr_verified',
      title: 'PR Verified! 🎉',
      body: `Your ${pr.exerciseName} PR (${pr.weightKg ? `${pr.weightKg}kg` : ''}${pr.reps} reps) has been verified!`,
      payload: {
        prId: pr.id,
        exerciseName: pr.exerciseName,
      },
    });

    return updated;
  }

  /**
   * Reject a PR (coach action)
   */
  async rejectPR(prId: string, coachUserId: string, reason?: string) {
    // Verify coach status
    const coachStaff = await this.prisma.gymStaff.findFirst({
      where: {
        authProviderId: coachUserId,
        role: { in: ['coach', 'admin', 'owner'] },
      },
    });

    if (!coachStaff) {
      throw new ForbiddenException('Only coaches can reject PRs');
    }

    const pr = await this.prisma.personalRecord.findUnique({
      where: { id: prId },
    });

    if (!pr) {
      throw new NotFoundException('Personal record not found');
    }

    if (pr.gymId !== coachStaff.gymId) {
      throw new ForbiddenException('Can only reject PRs in your gym');
    }

    const updated = await this.prisma.personalRecord.update({
      where: { id: prId },
      data: {
        status: 'rejected',
        rejectionReason: reason || 'Did not meet verification criteria',
        verifiedAt: null,
        verifiedByCoachId: null,
      },
    });

    // Send notification to user
    await this.notifications.create({
      gymId: pr.gymId,
      userId: pr.userId,
      type: 'pr_rejected',
      title: 'PR Needs Review',
      body: `Your ${pr.exerciseName} PR submission needs to be reviewed. ${reason || 'Please check with a coach.'}`,
      payload: {
        prId: pr.id,
        exerciseName: pr.exerciseName,
        reason,
      },
    });

    return updated;
  }

  /**
   * Get leaderboard for a specific exercise
   */
  async getLeaderboard(params: {
    gymId: string;
    exercise: 'Bench Press' | 'Squat' | 'Deadlift';
    gender?: 'male' | 'female' | 'other';
    limit?: number;
  }) {
    const { gymId, exercise, gender, limit = 10 } = params;

    const where: any = {
      gymId,
      exerciseName: exercise,
      status: 'verified',
    };

    if (gender) {
      where.user = { gender };
    }

    return this.prisma.personalRecord.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarPath: true,
            gender: true,
          },
        },
      },
      orderBy: [
        { weightKg: 'desc' },
        { reps: 'desc' },
      ],
      take: limit,
    });
  }

  /**
   * Get user's rank in a specific exercise leaderboard
   */
  async getUserRank(params: {
    userId: string;
    gymId: string;
    exercise: 'Bench Press' | 'Squat' | 'Deadlift';
    gender?: 'male' | 'female' | 'other';
  }) {
    const { userId, gymId, exercise, gender } = params;

    const userPR = await this.prisma.personalRecord.findUnique({
      where: {
        gymId_userId_exerciseName: { gymId, userId, exerciseName: exercise },
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarPath: true,
            gender: true,
          },
        },
      },
    });

    if (!userPR || userPR.status !== 'verified') {
      return { rank: null, total: 0, pr: null };
    }

    const where: any = {
      gymId,
      exerciseName: exercise,
      status: 'verified',
    };

    if (gender) {
      where.user = { gender };
    }

    // Count how many have better PRs
    const betterCount = await this.prisma.personalRecord.count({
      where: {
        ...where,
        OR: [
          { weightKg: { gt: userPR.weightKg || 0 } },
          {
            weightKg: userPR.weightKg,
            reps: { gt: userPR.reps },
          },
        ],
      },
    });

    const total = await this.prisma.personalRecord.count({ where });

    return {
      rank: betterCount + 1,
      total,
      pr: userPR, // Now includes user data
    };
  }
}
