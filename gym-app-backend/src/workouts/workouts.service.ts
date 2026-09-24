import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BuddiesService } from '../buddies/buddies.service';
import {
  CreateExerciseDto,
  CreateSessionDto,
  UpdateSessionDto,
  CreateSetDto,
  CreateRoutineDto,
  UpdateRoutineDto,
  RoutineExerciseDto,
  UpdateUserProfileDto,
} from './dto/workouts.dto';

@Injectable()
export class WorkoutsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    private buddies: BuddiesService,
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

  // ─── Personal routines ────────────────────────────────────────────────────

  private readonly routineInclude = {
    exercises: {
      include: { exercise: true },
      orderBy: { sortOrder: 'asc' as const },
    },
  };

  listRoutines(userId: string, gymId: string) {
    return this.prisma.workoutTemplate.findMany({
      where: {
        isActive: true,
        OR: [
          { source: 'user', createdByUserId: userId },
          { source: 'user', gymId },
          { source: 'coach_program', createdByUserId: userId },
          { source: 'coach_program', gymId, isActive: true },
        ],
      },
      include: this.routineInclude,
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getRoutine(userId: string, gymId: string, routineId: string) {
    const routine = await this.prisma.workoutTemplate.findFirst({
      where: {
        id: routineId,
        isActive: true,
        OR: [
          { source: 'user', createdByUserId: userId },
          { source: 'user', gymId },
          { source: 'coach_program', createdByUserId: userId },
          { source: 'coach_program', gymId },
        ],
      },
      include: this.routineInclude,
    });
    if (!routine) throw new NotFoundException('Routine not found');
    return routine;
  }

  createRoutine(userId: string, gymId: string, dto: CreateRoutineDto) {
    return this.prisma.workoutTemplate.create({
      data: {
        id: crypto.randomUUID(),
        name: dto.name.trim(),
        description: dto.description?.trim() || null,
        category: dto.category,
        difficulty: dto.difficulty,
        durationMins: dto.durationMins,
        source: 'user',
        gymId: dto.isShared ? gymId : null,
        createdByUserId: userId,
        exercises: {
          create: dto.exercises.map((exercise) =>
            this.routineExerciseData(exercise),
          ),
        },
      },
      include: this.routineInclude,
    });
  }

  async updateRoutine(
    userId: string,
    gymId: string,
    routineId: string,
    dto: UpdateRoutineDto,
  ) {
    const existing = await this.prisma.workoutTemplate.findFirst({
      where: {
        id: routineId,
        source: 'user',
        createdByUserId: userId,
        isActive: true,
      },
    });
    if (!existing) throw new NotFoundException('Routine not found');

    return this.prisma.workoutTemplate.update({
      where: { id: routineId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description.trim() || null }
          : {}),
        ...(dto.category !== undefined ? { category: dto.category } : {}),
        ...(dto.difficulty !== undefined ? { difficulty: dto.difficulty } : {}),
        ...(dto.durationMins !== undefined
          ? { durationMins: dto.durationMins }
          : {}),
        ...(dto.isShared !== undefined
          ? { gymId: dto.isShared ? gymId : null }
          : {}),
        ...(dto.exercises
          ? {
              exercises: {
                deleteMany: {},
                create: dto.exercises.map((exercise) =>
                  this.routineExerciseData(exercise),
                ),
              },
            }
          : {}),
      },
      include: this.routineInclude,
    });
  }

  async deleteRoutine(userId: string, routineId: string) {
    const existing = await this.prisma.workoutTemplate.findFirst({
      where: {
        id: routineId,
        source: 'user',
        createdByUserId: userId,
        isActive: true,
      },
    });
    if (!existing) throw new NotFoundException('Routine not found');

    await this.prisma.workoutTemplate.update({
      where: { id: routineId },
      data: { isActive: false },
    });
    return { deleted: true };
  }

  async copyRoutine(userId: string, gymId: string, routineId: string) {
    const source = await this.getRoutine(userId, gymId, routineId);
    return this.prisma.workoutTemplate.create({
      data: {
        id: crypto.randomUUID(),
        name: `${source.name} Copy`,
        description: source.description,
        category: source.category,
        difficulty: source.difficulty,
        durationMins: source.durationMins,
        source: 'user',
        gymId: null,
        createdByUserId: userId,
        exercises: {
          create: source.exercises.map((exercise) => ({
            id: crypto.randomUUID(),
            exerciseId: exercise.exerciseId,
            sortOrder: exercise.sortOrder,
            defaultSets: exercise.defaultSets,
            defaultReps: exercise.defaultReps,
            defaultWeightKg: exercise.defaultWeightKg,
            defaultDurationSecs: exercise.defaultDurationSecs,
            defaultDistanceM: exercise.defaultDistanceM,
            notes: exercise.notes,
          })),
        },
      },
      include: this.routineInclude,
    });
  }

  listGymPrograms(gymId: string, coachUserId?: string) {
    return this.prisma.workoutTemplate.findMany({
      where: {
        gymId,
        source: 'coach_program',
        isActive: true,
        ...(coachUserId ? { createdByUserId: coachUserId } : {}),
      },
      include: {
        ...this.routineInclude,
        createdBy: {
          select: { id: true, displayName: true, email: true },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async publishRoutine(
    userId: string,
    gymId: string,
    routineId: string,
    isStaff: boolean,
  ) {
    if (!isStaff) {
      throw new ForbiddenException('Only staff can publish gym programs');
    }

    const existing = await this.prisma.workoutTemplate.findFirst({
      where: {
        id: routineId,
        createdByUserId: userId,
        isActive: true,
        source: { in: ['user', 'coach_program'] },
      },
    });
    if (!existing) throw new NotFoundException('Routine not found');

    return this.prisma.workoutTemplate.update({
      where: { id: routineId },
      data: {
        gymId,
        source: 'coach_program',
        isActive: true,
      },
      include: this.routineInclude,
    });
  }

  async unpublishRoutine(
    userId: string,
    gymId: string,
    routineId: string,
    isStaff: boolean,
  ) {
    if (!isStaff) {
      throw new ForbiddenException('Only staff can unpublish gym programs');
    }

    const existing = await this.prisma.workoutTemplate.findFirst({
      where: {
        id: routineId,
        createdByUserId: userId,
        gymId,
        source: 'coach_program',
        isActive: true,
      },
    });
    if (!existing) throw new NotFoundException('Gym program not found');

    return this.prisma.workoutTemplate.update({
      where: { id: routineId },
      data: {
        gymId: null,
        source: 'user',
      },
      include: this.routineInclude,
    });
  }

  async getRoutineHistory(userId: string, gymId: string, routineId: string) {
    await this.getRoutine(userId, gymId, routineId);
    return this.prisma.workoutSession.findMany({
      where: {
        userId,
        gymId,
        templateId: routineId,
        endedAt: { not: null },
        deletedAt: null,
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
        sharedPost: {
          select: {
            id: true,
            certification: {
              select: {
                createdAt: true,
                coach: { select: { displayName: true } },
              },
            },
          },
        },
      },
      orderBy: { startedAt: 'desc' },
      take: 100,
    });
  }

  async getRoutineLeaderboard(
    userId: string,
    gymId: string,
    routineId: string,
    exerciseId: string,
    metric: string,
  ) {
    const routine = await this.getRoutine(userId, gymId, routineId);
    if (!routine.exercises.some((exercise) => exercise.exerciseId === exerciseId)) {
      throw new NotFoundException('Exercise is not part of this routine');
    }
    const selectedMetric = ['volume', 'weight', 'reps'].includes(metric)
      ? metric
      : 'volume';
    const sessions = await this.prisma.workoutSession.findMany({
      where: {
        gymId,
        templateId: routineId,
        endedAt: { not: null },
        deletedAt: null,
        sets: { some: { exerciseId, deletedAt: null } },
        // A certification on the workout post is the eligibility gate.
        sharedPost: {
          isDeleted: false,
          certification: { isNot: null },
        },
      },
      include: {
        user: { select: { id: true, displayName: true } },
        sets: {
          where: { exerciseId, deletedAt: null },
          select: { reps: true, weightKg: true },
        },
        sharedPost: {
          select: {
            certification: {
              select: {
                createdAt: true,
                coach: { select: { displayName: true } },
              },
            },
          },
        },
      },
    });

    const bestByUser = new Map<string, {
      userId: string;
      displayName: string;
      value: number;
      certifiedAt: Date;
      coachName: string;
    }>();
    for (const session of sessions) {
      const certification = session.sharedPost?.certification;
      if (!certification) continue;
      const values = session.sets.map((set) => {
        const reps = set.reps ?? 0;
        const weight = Number(set.weightKg ?? 0);
        if (selectedMetric === 'weight') return weight;
        if (selectedMetric === 'reps') return reps;
        return weight * reps;
      });
      const value = selectedMetric === 'volume'
        ? values.reduce((sum, current) => sum + current, 0)
        : Math.max(...values, 0);
      const current = bestByUser.get(session.user.id);
      if (!current || value > current.value) {
        bestByUser.set(session.user.id, {
          userId: session.user.id,
          displayName: session.user.displayName || 'Gym member',
          value,
          certifiedAt: certification.createdAt,
          coachName: certification.coach.displayName || 'Coach',
        });
      }
    }

    return {
      routineId,
      exerciseId,
      metric: selectedMetric,
      entries: [...bestByUser.values()]
        .sort((a, b) => b.value - a.value)
        .slice(0, 50),
    };
  }

  private routineExerciseData(exercise: RoutineExerciseDto) {
    return {
      id: crypto.randomUUID(),
      exerciseId: exercise.exerciseId,
      sortOrder: exercise.sortOrder,
      defaultSets: exercise.defaultSets,
      defaultReps: exercise.defaultReps,
      defaultWeightKg: exercise.defaultWeightKg,
      defaultDurationSecs: exercise.defaultDurationSecs,
      defaultDistanceM: exercise.defaultDistanceM,
      notes: exercise.notes?.trim() || null,
    };
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

  async createSession(userId: string, gymId: string, dto: CreateSessionDto) {
    if (dto.templateId) {
      const template = await this.prisma.workoutTemplate.findFirst({
        where: {
          id: dto.templateId,
          isActive: true,
          OR: [
            { source: 'user', createdByUserId: userId },
            { source: 'user', gymId },
            { source: 'coach_program', gymId },
            { source: 'coach_program', createdByUserId: userId },
          ],
        },
        select: { id: true },
      });
      if (!template) throw new NotFoundException('Routine not found');
    }

    const session = await this.prisma.workoutSession.create({
      data: {
        userId,
        gymId,
        templateId: dto.templateId,
        startedAt: dto.startedAt ? new Date(dto.startedAt) : new Date(),
        notes: dto.notes,
        participants: {
          create: {
            userId,
            role: 'host',
          },
        },
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
        participants: true,
      },
    });
    return session;
  }

  async createBuddySession(
    userId: string,
    gymId: string,
    buddyUserId: string,
    templateId?: string,
  ) {
    await this.buddies.assertActiveBuddy(userId, buddyUserId, gymId);

    if (templateId) {
      const template = await this.prisma.workoutTemplate.findFirst({
        where: {
          id: templateId,
          isActive: true,
          OR: [
            { source: 'user', createdByUserId: userId },
            { source: 'user', gymId },
            { source: 'coach_program', gymId },
          ],
        },
        select: { id: true },
      });
      if (!template) throw new NotFoundException('Routine not found');
    }

    const session = await this.prisma.workoutSession.create({
      data: {
        userId,
        gymId,
        templateId: templateId ?? null,
        startedAt: new Date(),
        participants: {
          create: [
            { userId, role: 'host' },
            { userId: buddyUserId, role: 'buddy' },
          ],
        },
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
        participants: {
          include: {
            user: { select: { id: true, displayName: true, email: true } },
          },
        },
      },
    });

    const host = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { displayName: true, email: true },
    });
    const hostName = host?.displayName || host?.email || 'Your buddy';

    await this.notifications.create({
      gymId,
      userId: buddyUserId,
      type: 'buddy_session',
      title: 'Buddy workout started',
      body: `${hostName} started a workout with you.`,
      payload: { sessionId: session.id },
    });

    return session;
  }

  private async assertCanWriteSession(userId: string, sessionId: string) {
    const session = await this.prisma.workoutSession.findFirst({
      where: { id: sessionId, deletedAt: null },
      include: {
        participants: { where: { userId }, select: { userId: true } },
      },
    });
    if (!session) throw new NotFoundException('Session not found');
    const isHost = session.userId === userId;
    const isParticipant = session.participants.length > 0;
    if (!isHost && !isParticipant) throw new ForbiddenException();
    return session;
  }

  async updateSession(userId: string, sessionId: string, dto: UpdateSessionDto) {
    await this.assertCanWriteSession(userId, sessionId);

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
        participants: true,
      },
    });
  }

  async deleteSession(userId: string, sessionId: string) {
    const session = await this.assertCanWriteSession(userId, sessionId);
    if (session.userId !== userId) {
      throw new ForbiddenException('Only the host can delete the session');
    }

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
      where: {
        deletedAt: null,
        OR: [
          { userId },
          { participants: { some: { userId } } },
        ],
      },
      include: {
        sets: {
          where: { deletedAt: null },
          include: { exercise: true },
          orderBy: { setNumber: 'asc' },
        },
        participants: {
          include: {
            user: { select: { id: true, displayName: true, email: true } },
          },
        },
      },
      orderBy: { startedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  // ─── Sets ──────────────────────────────────────────────────────────────────

  async addSet(userId: string, sessionId: string, dto: CreateSetDto) {
    const session = await this.assertCanWriteSession(userId, sessionId);

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
        // Persist the PR for in-session banners / profile stats.
        // Do not auto-post to the feed — that floods it with one card per set.
        // PRs surface on the member's shared workout post instead.
        await this.prisma.userAchievement.create({
          data: {
            id: crypto.randomUUID(),
            userId,
            gymId: session.gymId,
            achievementType: 'pr',
            value: `${dto.weightKg}kg × ${dto.reps} reps`,
            exerciseId: dto.exerciseId,
          },
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
    await this.assertCanWriteSession(userId, set.sessionId);

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
