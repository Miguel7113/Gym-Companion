import Link from 'next/link';
import {
  apiFetch,
  type DashboardRange,
  type GymDashboard,
  type ModerationPost,
} from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { percentChange } from '@/lib/format';
import { DashCard, PendingList, RangeTabs } from '@/components/dashboard/ui';
import { KpiGrid, type KpiItem } from '@/components/dashboard/kpi-cards';
import { ActivityChart } from '@/components/dashboard/activity-chart';
import { TierDonut } from '@/components/dashboard/tier-donut';
import { BusyHoursHeatmap } from '@/components/dashboard/busy-hours-heatmap';
import { CoachStack } from '@/components/dashboard/coach-stack';
import { GoalRing } from '@/components/dashboard/goal-ring';
import { ProgramList } from '@/components/dashboard/program-list';
import { FeedCard } from '@/components/dashboard/feed-card';

const RANGE_NOUN: Record<DashboardRange, string> = {
  today: 'yesterday',
  week: 'last week',
  month: 'last month',
};

function parseRange(value?: string): DashboardRange {
  return value === 'today' || value === 'month' ? value : 'week';
}

function buildKpis(data: GymDashboard): KpiItem[] {
  const { kpis, range } = data;
  const vs = RANGE_NOUN[range];
  const workoutChange = percentChange(kpis.workouts.current, kpis.workouts.previous);
  const newMembers = kpis.members.newCurrent;

  return [
    {
      label: 'Members',
      value: kpis.members.value,
      icon: 'members',
      delta: newMembers > 0 ? `+${newMembers} new` : 'No new signups',
      tone: newMembers > 0 ? 'up' : 'neutral',
      href: '/dashboard/members',
    },
    {
      label: 'Training now',
      value: kpis.activeNow,
      icon: 'active',
      delta: 'live',
      tone: 'up',
      live: true,
    },
    {
      label: range === 'today' ? 'Workouts today' : range === 'week' ? 'Workouts · 7 days' : 'Workouts · 30 days',
      value: kpis.workouts.current,
      icon: 'workouts',
      delta:
        workoutChange === null
          ? `vs 0 ${vs}`
          : `${workoutChange > 0 ? '+' : ''}${workoutChange}% vs ${vs}`,
      tone: workoutChange === null || workoutChange >= 0 ? 'up' : 'down',
      href: '/dashboard/analytics' + (range === 'week' ? '' : `?range=${range}`),
    },
    {
      label: 'Pending approvals',
      value: kpis.pending,
      icon: 'pending',
      delta: kpis.pending > 0 ? 'Needs review' : 'All clear',
      tone: kpis.pending > 0 ? 'warn' : 'up',
      href: '/dashboard/roster',
    },
  ];
}

export default async function DashboardPage({
  searchParams,
}: {
  searchParams?: Promise<{ range?: string; message?: string; error?: string }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};
  const range = parseRange(params.range);

  let data: GymDashboard | null = null;
  let posts: ModerationPost[] = [];
  let error: string | null = null;

  try {
    [data, posts] = await Promise.all([
      apiFetch<GymDashboard>(`/gyms/${session.gymId}/dashboard?range=${range}`, {
        token: session.accessToken,
      }),
      apiFetch<ModerationPost[]>('/staff/social/recent?limit=3', {
        token: session.accessToken,
      }),
    ]);
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load overview.';
  }

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="tdash-page-title">Overview</h1>
        <RangeTabs basePath="/dashboard" current={range} />
      </div>

      {params.message ? <div className="alert alert-success">{params.message}</div> : null}
      {error || params.error ? (
        <div className="alert alert-error">{params.error ?? error}</div>
      ) : null}

      {data ? (
        <>
          <KpiGrid items={buildKpis(data)} />

          <div className="tdash-grid-wide">
            <ActivityChart activity={data.activity} />
            <TierDonut tiers={data.tiers} />
          </div>

          <div className="tdash-grid-wide">
            <DashCard
              title="Community feed"
              action={
                <Link href="/dashboard/feed" className="tdash-link">
                  View all
                </Link>
              }
            >
              {posts.length === 0 ? (
                <p className="tdash-empty">No posts yet. Shared workouts will show up here.</p>
              ) : (
                <div className="flex flex-col gap-4">
                  {posts.map((post) => (
                    <FeedCard key={post.id} post={post} returnTo="/dashboard" />
                  ))}
                </div>
              )}
            </DashCard>
            <div className="tdash-col">
              <BusyHoursHeatmap busyHours={data.busyHours} />
              <CoachStack coaches={data.coaches} />
            </div>
          </div>

          <div className="tdash-grid-3">
            <DashCard
              title="Top programs"
              meta={range === 'today' ? 'Today' : range === 'week' ? 'Last 7 days' : 'Last 30 days'}
            >
              <ProgramList programs={data.topPrograms} />
            </DashCard>
            <DashCard
              title="Pending approvals"
              action={
                <Link href="/dashboard/roster" className="tdash-link">
                  Review
                </Link>
              }
            >
              <PendingList entries={data.pendingRoster} />
              {data.kpis.flagged > 0 ? (
                <Link href="/dashboard/feed" className="tdash-flag-link">
                  {data.kpis.flagged} flagged post{data.kpis.flagged === 1 ? '' : 's'} to review
                </Link>
              ) : null}
            </DashCard>
            <GoalRing goal={data.weeklyGoal} />
          </div>
        </>
      ) : null}
    </>
  );
}
