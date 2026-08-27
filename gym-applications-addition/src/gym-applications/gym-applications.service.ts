import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseService } from '../supabase/supabase.service';
import { SubmitGymApplicationDto } from './dto/submit-application.dto';

@Injectable()
export class GymApplicationsService {
  constructor(
    private prisma: PrismaService,
    private supabase: SupabaseService,
  ) {}

  /** Public — the "Apply to join" form on the marketing site. No account
   * is created yet, just a lead for you to review. */
  async submit(dto: SubmitGymApplicationDto) {
    return this.prisma.gymApplication.create({
      data: {
        gymName: dto.gymName,
        contactName: dto.contactName,
        email: dto.email,
        phone: dto.phone,
        message: dto.message,
      },
    });
  }

  /** Admin-only — list pending applications to review. */
  async listPending() {
    return this.prisma.gymApplication.findMany({
      where: { status: 'pending' },
      orderBy: { submittedAt: 'asc' },
    });
  }

  /**
   * Admin-only — approving an application is what actually creates the
   * real Gym + first GymStaff account (reusing the exact same creation
   * logic as the earlier open self-serve design, just gated behind your
   * manual review instead of being public). Sends an OTP so the gym
   * owner can complete their first login immediately after.
   */
  async approve(applicationId: string) {
    const application = await this.prisma.gymApplication.findUnique({
      where: { id: applicationId },
    });
    if (!application) throw new NotFoundException('Application not found');
    if (application.status !== 'pending') {
      throw new ConflictException('Application already reviewed');
    }

    const existingStaff = await this.prisma.gymStaff.findUnique({
      where: { email: application.email },
    });
    if (existingStaff) throw new ConflictException('An account already exists for this email.');

    const { gym } = await this.prisma.$transaction(async (tx) => {
      const gym = await tx.gym.create({
        data: { name: application.gymName, subscriptionTier: 'trial', isActive: true },
      });
      await tx.gymStaff.create({
        data: { gymId: gym.id, email: application.email, role: 'owner' },
      });
      await tx.gymApplication.update({
        where: { id: applicationId },
        data: { status: 'approved', reviewedAt: new Date(), resultingGymId: gym.id },
      });
      return { gym };
    });

    await this.supabase.sendEmailOtp(application.email);
    return { status: 'approved' as const, gymId: gym.id };
  }

  /** Admin-only — reject with no account created. */
  async reject(applicationId: string) {
    return this.prisma.gymApplication.update({
      where: { id: applicationId },
      data: { status: 'rejected', reviewedAt: new Date() },
    });
  }
}
