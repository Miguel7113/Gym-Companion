import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type DashboardRange = 'today' | 'week' | 'month';

const DAY_MS = 86_400_000;
const HISTORY_DAYS = 62;
const HEATMAP_DAYS = 28;
const HEATMAP_HOURS = Array.from({ length: 18 }, (_, i) => i + 5);
const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
/** Sessions left open longer than this are treated as abandoned, not "training now". */
const ACTIVE_SESSION_MAX_MS = 4 * 60 * 60 * 1000;

type HourRow = { day: string; dow: number; hour: number; count: number };
type DayRow = { day: string; count: number };

export function parseDashboardRange(value?: string): DashboardRange {
  return value === 'today' || value === 'month' ? value : 'week';
}

function safeTimeZone(tz: string | null | undefined) {
  if (!tz) return 'UTC';
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return tz;
  } catch {
    return 'UTC';
  }
}

function localDateKey(date: Date, tz: string) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

function localHour(date: Date, tz: string) {
  return Number(
    new Intl.DateTimeFormat('en-GB', {
      timeZone: tz,
      hour: '2-digit',
      hourCycle: 'h23',
    }).format(date),
  );
}

function shiftDateKey(key: string, days: number) {
  const d = new Date(`${key}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** 0 = Monday … 6 = Sunday */
function isoWeekdayIndex(key: string) {
  return (new Date(`${key}T00:00:00Z`).getUTCDay() + 6) % 7;
}

function dayLabel(key: string, range: DashboardRange) {
  if (range === 'week') return WEEKDAYS[isoWeekdayIndex(key)];
  return new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'short',
    timeZone: 'UTC',
  }).format(new Date(`${key}T00:00:00Z`));
}

function hourLabel(hour: number) {
  if (hour === 0) return '12a';
  if (hour === 12) return '12p';
  return hour < 12 ? `${hour}a` : `${hour - 12}p`;
}

function sumRange(byDay: Map<string, number>, fromKey: string, days: number) {
  let total = 0;
  for (let i = 0; i < days; i++) total += byDay.get(shiftDateKey(fromKey, i)) ?? 0;
  return total;
}

@Injectable()
export class GymDashboardService {
  constructor(private prisma: PrismaService) {}

  async getDashboard(gymId: string, range: DashboardRange) {
    const gym = await this.prisma.gym.findUnique({
      where: { id: gymId },
      select: { timezone: true },
    });
    if (!gym) throw new NotFoundException('Gym not found');

    const tz = safeTimeZone(gym.timezone);
    const now = new Date();
    const since = new Date(now.getTime() - HISTORY_DAYS * DAY_MS);
    const todayKey = localDateKey(now, tz);
    const currentHour = localHour(now, tz);

    const [
      sessionRows,
      memberRows,
      memberCount,
      openSessions,
      pendingCount,
      flaggedCount,
      tierRows,
      pendingRoster,
      coachStaff,
    ] = await Promise.all([
      this.prisma.$queryRaw<HourRow[]>`
        SELECT to_char(local_ts, 'YYYY-MM-DD') AS day,
               EXTRACT(ISODOW FROM local_ts)::int AS dow,
               EXTRACT(HOUR FROM local_ts)::int AS hour,
               COUNT(*)::int AS count
        FROM (
          SELECT (started_at AT TIME ZONE 'UTC') AT TIME ZONE ${tz} AS local_ts
          FROM workout_sessions
          WHERE gym_id = ${gymId} AND deleted_at IS NULL AND started_at >= ${since}
        ) s
        GROUP BY 1, 2, 3`,
      this.prisma.$queryRaw<DayRow[]>`
        SELECT to_char((created_at AT TIME ZONE 'UTC') AT TIME ZONE ${tz}, 'YYYY-MM-DD') AS day,
               COUNT(*)::int AS count
        FROM users
        WHERE gym_id = ${gymId} AND created_at >= ${since}
        GROUP BY 1`,
      this.prisma.user.count({ where: { gymId } }),
      this.prisma.workoutSession.findMany({
        where: {
          gymId,
          endedAt: null,
          deletedAt: null,
          startedAt: { gte: new Date(now.getTime() - ACTIVE_SESSION_MAX_MS) },
        },
        select: { userId: true, participants: { select: { userId: true } } },
      }),
      this.prisma.gymRoster.count({ where: { gymId, status: 'pending' } }),
      this.prisma.post.count({
        where: { gymId, isFlagged: true, isDeleted: false },
      }),
      this.prisma.user.groupBy({
        by: ['subscriptionTier'],
        where: { gymId },
        _count: { _all: true },
      }),
      this.prisma.gymRoster.findMany({
        where: { gymId, status: 'pending' },
        select: {
          id: true,
          memberName: true,
          email: true,
          phone: true,
          createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 4,
      }),
      this.prisma.gymStaff.findMany({
        where: { gymId, role: 'coach' },
        select: { id: true, email: true, authProviderId: true },
        orderBy: { email: 'asc' },
      }),
    ]);

    const sessionsByDay = new Map<string, number>();
    const hourlyByDay = new Map<string, number[]>();
    for (const row of sessionRows) {
      sessionsByDay.set(row.day, (sessionsByDay.get(row.day) ?? 0) + row.count);
      const hours = hourlyByDay.get(row.day) ?? new Array<number>(24).fill(0);
      hours[row.hour] += row.count;
      hourlyByDay.set(row.day, hours);
    }
    const membersByDay = new Map(memberRows.map((r) => [r.day, r.count]));

    const days = range === 'month' ? 30 : range === 'week' ? 7 : 1;
    const currentStart = shiftDateKey(todayKey, -(days - 1));
    const previousStart = shiftDateKey(currentStart, -days);

    const activity = this.buildActivity(
      range,
      todayKey,
      currentHour,
      currentStart,
      previousStart,
      days,
      sessionsByDay,
      hourlyByDay,
    );

    let workoutsCurrent = sumRange(sessionsByDay, currentStart, days);
    let workoutsPrevious = sumRange(sessionsByDay, previousStart, days);
    if (range === 'today') {
      // Compare today so far against yesterday up to the same hour.
      const yesterday = hourlyByDay.get(shiftDateKey(todayKey, -1)) ?? [];
      workoutsPrevious = yesterday
        .slice(0, currentHour + 1)
        .reduce((a, b) => a + b, 0);
      workoutsCurrent = (hourlyByDay.get(todayKey) ?? [])
        .slice(0, currentHour + 1)
        .reduce((a, b) => a + b, 0);
    }

    const activeUsers = new Set<string>();
    for (const session of openSessions) {
      activeUsers.add(session.userId);
      for (const p of session.participants) activeUsers.add(p.userId);
    }

    return {
      range,
      timezone: tz,
      generatedAt: now.toISOString(),
      kpis: {
        members: {
          value: memberCount,
          newCurrent: sumRange(membersByDay, currentStart, days),
          newPrevious: sumRange(membersByDay, previousStart, days),
        },
        activeNow: activeUsers.size,
        workouts: { current: workoutsCurrent, previous: workoutsPrevious },
        pending: pendingCount,
        flagged: flaggedCount,
      },
      activity,
      tiers: tierRows
        .map((row) => ({
          name: row.subscriptionTier || 'free',
          value: row._count._all,
        }))
        .sort((a, b) => b.value - a.value),
      busyHours: this.buildBusyHours(todayKey, hourlyByDay),
      weeklyGoal: this.buildWeeklyGoal(todayKey, sessionsByDay),
      topPrograms: await this.topPrograms(gymId, currentStart, days, tz),
      coaches: await this.coachSummary(gymId, coachStaff, activeUsers),
      pendingRoster: pendingRoster.map((entry) => ({
        id: entry.id,
        name: entry.memberName || entry.email || entry.phone || 'Unnamed',
        contact: entry.email || entry.phone || null,
        createdAt: entry.createdAt,
      })),
    };
  }

  private buildActivity(
    range: DashboardRange,
    todayKey: string,
    currentHour: number,
    currentStart: string,
    previousStart: string,
    days: number,
    sessionsByDay: Map<string, number>,
    hourlyByDay: Map<string, number[]>,
  ) {
    if (range === 'today') {
      const today = hourlyByDay.get(todayKey) ?? new Array<number>(24).fill(0);
      const yesterday =
        hourlyByDay.get(shiftDateKey(todayKey, -1)) ?? new Array<number>(24).fill(0);
      return {
        granularity: 'hour' as const,
        currentLabel: 'Today',
        previousLabel: 'Yesterday',
        points: HEATMAP_HOURS.map((hour) => ({
          label: hourLabel(hour),
          current: hour <= currentHour ? today[hour] : null,
          previous: yesterday[hour],
        })),
      };
    }

    return {
      granularity: 'day' as const,
      currentLabel: range === 'week' ? 'Last 7 days' : 'Last 30 days',
      previousLabel: range === 'week' ? 'Previous 7 days' : 'Previous 30 days',
      points: Array.from({ length: days }, (_, i) => {
        const key = shiftDateKey(currentStart, i);
        return {
          label: dayLabel(key, range),
          current: sessionsByDay.get(key) ?? 0,
          previous: sessionsByDay.get(shiftDateKey(previousStart, i)) ?? 0,
        };
      }),
    };
  }

  private buildBusyHours(todayKey: string, hourlyByDay: Map<string, number[]>) {
    const grid = WEEKDAYS.map(() => HEATMAP_HOURS.map(() => 0));
    const firstKey = shiftDateKey(todayKey, -(HEATMAP_DAYS - 1));
    for (const [key, hours] of hourlyByDay) {
      if (key < firstKey || key > todayKey) continue;
      const row = grid[isoWeekdayIndex(key)];
      HEATMAP_HOURS.forEach((hour, col) => {
        row[col] += hours[hour];
      });
    }
    const max = Math.max(0, ...grid.flat());
    return { days: WEEKDAYS, hours: HEATMAP_HOURS, grid, max, windowDays: HEATMAP_DAYS };
  }

  private buildWeeklyGoal(todayKey: string, sessionsByDay: Map<string, number>) {
    const weekdayIndex = isoWeekdayIndex(todayKey);
    const mondayKey = shiftDateKey(todayKey, -weekdayIndex);
    const current = sumRange(sessionsByDay, mondayKey, weekdayIndex + 1);
    const priorWeeks = [1, 2, 3, 4].map((w) =>
      sumRange(sessionsByDay, shiftDateKey(mondayKey, -7 * w), 7),
    );
    const target = Math.round(priorWeeks.reduce((a, b) => a + b, 0) / 4);
    return { current, target, daysLeft: 6 - weekdayIndex };
  }

  private async topPrograms(gymId: string, fromKey: string, days: number, tz: string) {
    // Local-day window converted to a UTC lower bound with a one-day margin, then filtered precisely.
    const lowerBound = new Date(new Date(`${fromKey}T00:00:00Z`).getTime() - DAY_MS);
    const sessions = await this.prisma.workoutSession.findMany({
      where: {
        gymId,
        deletedAt: null,
        templateId: { not: null },
        startedAt: { gte: lowerBound },
      },
      select: { templateId: true, startedAt: true },
    });

    const endKey = shiftDateKey(fromKey, days - 1);
    const counts = new Map<string, number>();
    for (const s of sessions) {
      const key = localDateKey(s.startedAt, tz);
      if (key < fromKey || key > endKey) continue;
      counts.set(s.templateId!, (counts.get(s.templateId!) ?? 0) + 1);
    }
    const top = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5);
    if (top.length === 0) return [];

    const templates = await this.prisma.workoutTemplate.findMany({
      where: { id: { in: top.map(([id]) => id) } },
      select: {
        id: true,
        name: true,
        source: true,
        createdBy: { select: { displayName: true } },
      },
    });
    const byId = new Map(templates.map((t) => [t.id, t]));

    return top
      .map(([id, sessionsCount]) => {
        const t = byId.get(id);
        if (!t) return null;
        return {
          id,
          name: t.name,
          source: t.source,
          coachName: t.source === 'coach_program' ? (t.createdBy?.displayName ?? 'Coach') : null,
          sessions: sessionsCount,
        };
      })
      .filter((p): p is NonNullable<typeof p> => p !== null);
  }

  private async coachSummary(
    gymId: string,
    staff: { id: string; email: string; authProviderId: string | null }[],
    activeUsers: Set<string>,
  ) {
    const authIds = staff
      .map((s) => s.authProviderId)
      .filter((id): id is string => !!id);
    const users = authIds.length
      ? await this.prisma.user.findMany({
          where: { gymId, authProviderId: { in: authIds } },
          select: { id: true, displayName: true, authProviderId: true },
        })
      : [];
    const userByAuth = new Map(users.map((u) => [u.authProviderId!, u]));

    const programRows = users.length
      ? await this.prisma.workoutTemplate.groupBy({
          by: ['createdByUserId'],
          where: {
            gymId,
            source: 'coach_program',
            isActive: true,
            createdByUserId: { in: users.map((u) => u.id) },
          },
          _count: { _all: true },
        })
      : [];
    const programsByUser = new Map(
      programRows.map((r) => [r.createdByUserId!, r._count._all]),
    );

    const list = staff.map((s) => {
      const user = s.authProviderId ? userByAuth.get(s.authProviderId) : undefined;
      return {
        staffId: s.id,
        name: user?.displayName || s.email.split('@')[0],
        email: s.email,
        hasAppAccount: !!user,
        isTrainingNow: user ? activeUsers.has(user.id) : false,
        programCount: user ? (programsByUser.get(user.id) ?? 0) : 0,
      };
    });
    list.sort((a, b) => Number(b.isTrainingNow) - Number(a.isTrainingNow));

    return {
      total: list.length,
      trainingNow: list.filter((c) => c.isTrainingNow).length,
      list,
    };
  }
}
