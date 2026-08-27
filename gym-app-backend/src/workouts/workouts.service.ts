import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SocialService } from '../social/social.service';
import {
  CreateExerciseDto,
  CreateSessionDto,
  UpdateSessionDto,
  CreateSetDto,
  UpdateUserProfileDto,
} from './dto/workouts.dto';

@Injectable()
export class WorkoutsService {
  constructor(
    private prisma: PrismaService,
    private socialService: SocialService,
  ) {}

  // ─── Exercises ─────────────────────────────────────────────────────────────

  listExercises(
    q?: string,
    bodyPart?: string,
    category?: string,
    equipment?: string,
    limit = 500,
    offset = 0,
    isCustom?: boolean,
  ) {
    return this.prisma.exercise.findMany({
      where: {
        ...(q ? { name: { contains: q, mode: 'insensitive' as const } } : {}),
        ...(bodyPart ? { bodyParts: { has: bodyPart } } : {}),
        ...(category ? { category: { equals: category, mode: 'insensitive' as const } } : {}),
        ...(equipment ? { equipments: { has: equipment } } : {}),
        ...(isCustom !== undefined ? { isCustom } : {}),
      },
      select: {
        id: true,
        name: true,
        category: true,
        bodyParts: true,
        targetMuscles: true,
        secondaryMuscles: true,
        equipments: true,
        difficulty: true,
        gifUrl: true,
        overview: true,
        instructions: true,
        isCustom: true,
        externalId: true,
      },
      orderBy: { name: 'asc' },
      take: limit,
      skip: offset,
    });
  }

  async getExercise(exerciseId: string) {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id: exerciseId },
    });
    if (!exercise) throw new NotFoundException('Exercise not found');
    return exercise;
  }

  async listBodyParts(): Promise<string[]> {
    // Use DISTINCT unnest with actual DB column names (snake_case).
    // Prisma @map() fields only apply to the ORM layer — raw SQL must use
    // the real column names: body_parts, is_custom (not bodyParts, isCustom).
    const rows = await this.prisma.$queryRaw<{ part: string }[]>`
      SELECT DISTINCT unnest(body_parts) AS part
      FROM exercises
      WHERE is_custom = false
        AND body_parts IS NOT NULL
      ORDER BY part ASC
    `;
    return rows.map((r) => r.part);
  }

  async listEquipments(): Promise<string[]> {
    // Same pattern — equipments has no @map so it stays "equipments" in the DB.
    const rows = await this.prisma.$queryRaw<{ equip: string }[]>`
      SELECT DISTINCT unnest(equipments) AS equip
      FROM exercises
      WHERE is_custom = false
        AND equipments IS NOT NULL
      ORDER BY equip ASC
    `;
    return rows.map((r) => r.equip).filter((e) => e && e.trim() !== '');
  }

  createExercise(userId: string, dto: CreateExerciseDto) {
    return this.prisma.exercise.create({
      data: {
        name: dto.name,
        category: dto.category,
        bodyParts: [],
        targetMuscles: [],
        secondaryMuscles: [],
        equipments: [],
        exerciseTypes: [],
        instructions: [],
        isCustom: true,
        createdByUserId: userId,
      },
    });
  }

  // ─── Templates (Programs) ──────────────────────────────────────────────────

  // Returns system templates + gym-specific templates visible to this user.
  // Local/hardcoded programs in Flutter don't call this — it's for future
  // gym dashboard integration.
  async listTemplates(gymId: string) {
    return this.prisma.workoutTemplate.findMany({
      where: {
        isActive: true,
        OR: [
          { source: 'system', gymId: null },
          { gymId },
        ],
      },
      include: {
        exercises: {
          include: { exercise: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getTemplate(templateId: string) {
    const template = await this.prisma.workoutTemplate.findUnique({
      where: { id: templateId },
      include: {
        exercises: {
          include: { exercise: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
    if (!template) throw new NotFoundException('Template not found');
    return template;
  }

  // ─── Saved Exercises ───────────────────────────────────────────────────────

  async getSavedExercises(userId: string) {
    const rows = await this.prisma.savedExercise.findMany({
      where: { userId },
      include: {
        exercise: {
          select: {
            id: true, name: true, category: true, bodyParts: true,
            targetMuscles: true, equipments: true, difficulty: true,
            gifUrl: true, overview: true, instructions: true, isCustom: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(r => r.exercise);
  }

  async saveExercise(userId: string, exerciseId: string) {
    // Upsert — safe to call multiple times
    return this.prisma.savedExercise.upsert({
      where: { userId_exerciseId: { userId, exerciseId } },
      create: { id: crypto.randomUUID(), userId, exerciseId },
      update: {},
    });
  }

  async unsaveExercise(userId: string, exerciseId: string) {
    await this.prisma.savedExercise.deleteMany({ where: { userId, exerciseId } });
    return { deleted: true };
  }

  // ─── Saved Programs ────────────────────────────────────────────────────────

  async getSavedPrograms(userId: string) {
    const rows = await this.prisma.savedProgram.findMany({
      where: { userId },
      include: {
        template: {
          include: {
            exercises: {
              include: { exercise: true },
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(r => r.template);
  }

  async saveProgram(userId: string, templateId: string) {
    return this.prisma.savedProgram.upsert({
      where: { userId_templateId: { userId, templateId } },
      create: { id: crypto.randomUUID(), userId, templateId },
      update: {},
    });
  }

  async unsaveProgram(userId: string, templateId: string) {
    await this.prisma.savedProgram.deleteMany({ where: { userId, templateId } });
    return { deleted: true };
  }

  // ─── Recently Used ─────────────────────────────────────────────────────────

  async getRecentlyUsed(userId: string, limit = 10) {
    const rows = await this.prisma.recentlyUsedExercise.findMany({
      where: { userId },
      include: {
        exercise: {
          select: {
            id: true, name: true, category: true, bodyParts: true,
            targetMuscles: true, equipments: true, difficulty: true,
            gifUrl: true, overview: true, instructions: true, isCustom: true,
          },
        },
      },
      orderBy: { usedAt: 'desc' },
      take: limit,
    });
    return rows.map(r => r.exercise);
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  async updateProfile(userId: string, dto: UpdateUserProfileDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.displayName !== undefined ? { displayName: dto.displayName } : {}),
        ...(dto.gender !== undefined ? { gender: dto.gender } : {}),
        ...(dto.bodyWeightKg !== undefined ? { bodyWeightKg: dto.bodyWeightKg } : {}),
        ...(dto.heightCm !== undefined ? { heightCm: dto.heightCm } : {}),
      },
      select: {
        id: true, displayName: true, gender: true,
        bodyWeightKg: true, heightCm: true, email: true,
      },
    });
  }

  // ─── Sessions ──────────────────────────────────────────────────────────────

  createSession(userId: string, gymId: string, dto: CreateSessionDto) {
    return this.prisma.workoutSession.create({
      data: {
        userId,
        gymId,
        startedAt: dto.startedAt ? new Date(dto.startedAt) : new Date(),
        notes: dto.notes,
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
      },
    });
  }

  async updateSession(userId: string, sessionId: string, dto: UpdateSessionDto) {
    const session = await this.prisma.workoutSession.findFirst({
      where: { id: sessionId, deletedAt: null },
    });
    if (!session) throw new NotFoundException('Session not found');
    if (session.userId !== userId) throw new ForbiddenException();

    return this.prisma.workoutSession.update({
      where: { id: sessionId },
      data: {
        ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
        ...(dto.ended
          ? { endedAt: dto.endedAt ? new Date(dto.endedAt) : new Date() }
          : {}),
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
      },
    });
  }

  async deleteSession(userId: string, sessionId: string) {
    const session = await this.prisma.workoutSession.findFirst({
      where: { id: sessionId, deletedAt: null },
    });
    if (!session) throw new NotFoundException('Session not found');
    if (session.userId !== userId) throw new ForbiddenException();

    await this.prisma.workoutSet.updateMany({
      where: { sessionId, deletedAt: null },
      data: { deletedAt: new Date() },
    });
    await this.prisma.workoutSession.update({
      where: { id: sessionId },
      data: { deletedAt: new Date() },
    });
    return { deleted: true };
  }

  listSessions(userId: string, limit: number, offset: number) {
    return this.prisma.workoutSession.findMany({
      where: { userId, deletedAt: null },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
      },
      orderBy: { startedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  // ─── Sets ──────────────────────────────────────────────────────────────────

  async addSet(userId: string, sessionId: string, dto: CreateSetDto) {
    const session = await this.prisma.workoutSession.findFirst({
      where: { id: sessionId, deletedAt: null },
    });
    if (!session) throw new NotFoundException('Session not found');
    if (session.userId !== userId) throw new ForbiddenException();

    const set = await this.prisma.workoutSet.create({
      data: {
        sessionId,
        exerciseId: dto.exerciseId,
        setNumber: dto.setNumber,
        reps: dto.reps,
        weightKg: dto.weightKg,
        rpe: dto.rpe,
        assistKg: dto.assistKg,
        durationSecs: dto.durationSecs,
        distanceM: dto.distanceM,
        speedKph: dto.speedKph,
      },
      include: { exercise: true },
    });

    // Update recently used
    await this.prisma.recentlyUsedExercise.upsert({
      where: { userId_exerciseId: { userId, exerciseId: dto.exerciseId } },
      create: {
        id: crypto.randomUUID(),
        userId,
        exerciseId: dto.exerciseId,
        useCount: 1,
      },
      update: {
        usedAt: new Date(),
        useCount: { increment: 1 },
      },
    });

    // PR detection — strength sets only
    let isPr = false;
    if (dto.reps && dto.weightKg) {
      const currentVolume = dto.weightKg * dto.reps;
      const previousBest = await this.prisma.workoutSet.findFirst({
        where: {
          id: { not: set.id },
          exerciseId: dto.exerciseId,
          deletedAt: null,
          session: { userId, deletedAt: null },
          reps: { not: null },
          weightKg: { not: null },
        },
        orderBy: [{ weightKg: 'desc' }, { reps: 'desc' }],
      });

      if (!previousBest) {
        isPr = true;
      } else {
        const prevVolume = Number(previousBest.weightKg) * (previousBest.reps ?? 0);
        isPr = currentVolume > prevVolume;
      }

      if (isPr) {
        const achievement = await this.prisma.userAchievement.create({
          data: {
            id: crypto.randomUUID(),
            userId,
            gymId: session.gymId,
            achievementType: 'pr',
            value: `${dto.weightKg}kg × ${dto.reps} reps`,
            exerciseId: dto.exerciseId,
          },
        });

        // Auto-create a social post for this PR
        // Fire and forget — don't fail the set save if this errors
        this.socialService.createAchievementPost({
          userId,
          gymId: session.gymId,
          achievementId: achievement.id,
          exerciseName: set.exercise?.name ?? 'Exercise',
          value: `${dto.weightKg}kg × ${dto.reps} reps`,
          bodyParts: set.exercise?.bodyParts ?? [],
        }).catch((err) => {
          console.error('[WorkoutsService] createAchievementPost failed:', err);
        });
      }
    }

    return { set, isPr };
  }

  async deleteSet(userId: string, setId: string) {
    const set = await this.prisma.workoutSet.findFirst({
      where: { id: setId, deletedAt: null },
      include: { session: true },
    });
    if (!set) throw new NotFoundException('Set not found');
    if (set.session.userId !== userId) throw new ForbiddenException();

    await this.prisma.workoutSet.update({
      where: { id: setId },
      data: { deletedAt: new Date() },
    });
    return { deleted: true };
  }

  // ─── Progress ──────────────────────────────────────────────────────────────

  async getProgress(userId: string, exerciseId: string) {
    const sets = await this.prisma.workoutSet.findMany({
      where: {
        exerciseId,
        deletedAt: null,
        session: { userId, deletedAt: null },
      },
      include: { session: true },
      orderBy: { createdAt: 'asc' },
    });

    return sets.map((s) => ({
      date: s.session.startedAt,
      reps: s.reps,
      weightKg: s.weightKg ? Number(s.weightKg) : null,
      rpe: s.rpe ? Number(s.rpe) : null,
      durationSecs: s.durationSecs,
      distanceM: s.distanceM ? Number(s.distanceM) : null,
      speedKph: s.speedKph ? Number(s.speedKph) : null,
    }));
  }
}
