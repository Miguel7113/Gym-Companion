import { apiFetch, type DashboardRange, type GymDashboard } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { percentChange } from '@/lib/format';
import { DashCard, RangeTabs } from '@/components/dashboard/ui';
import { ActivityChart } from '@/components/dashboard/activity-chart';
import { TierDonut } from '@/components/dashboard/tier-donut';
import { BusyHoursHeatmap } from '@/components/dashboard/busy-hours-heatmap';
import { ProgramList } from '@/components/dashboard/program-list';
import { GoalRing } from '@/components/dashboard/goal-ring';

function parseRange(value?: string): DashboardRange {
  return value === 'today' || value === 'month' ? value : 'week';
}

function Stat({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div>
      <div className="text-xs text-neutral-400">{label}</div>
      <div className="tnum mt-0.5 text-[22px] font-medium leading-tight">{value}</div>
      {sub ? <div className="mt-0.5 text-xs text-neutral-500">{sub}</div> : null}
    </div>
  );
}

export default async function AnalyticsPage({
  searchParams,
}: {
  searchParams?: Promise<{ range?: string }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};
  const range = parseRange(params.range);

  let data: GymDashboard | null = null;
  let error: string | null = null;
  try {
    data = await apiFetch<GymDashboard>(`/gyms/${session.gymId}/dashboard?range=${range}`, {
      token: session.accessToken,
    });
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load analytics.';
  }

  const change = data ? percentChange(data.kpis.workouts.current, data.kpis.workouts.previous) : null;
  const perMember =
    data && data.kpis.members.value > 0
      ? (data.kpis.workouts.current / data.kpis.members.value).toFixed(1)
      : '0';

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="tdash-page-title">Analytics</h1>
        <RangeTabs basePath="/dashboard/analytics" current={range} />
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      {data ? (
        <>
          <div className="tdash-card">
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat
                label="Workouts"
                value={data.kpis.workouts.current.toLocaleString()}
                sub={
                  change === null
                    ? 'No prior data'
                    : `${change > 0 ? '+' : ''}${change}% vs previous period`
                }
              />
              <Stat label="Per member" value={perMember} sub="Workouts in this period" />
              <Stat
                label="New members"
                value={data.kpis.members.newCurrent.toLocaleString()}
                sub={`${data.kpis.members.newPrevious} in previous period`}
              />
              <Stat
                label="Training now"
                value={data.kpis.activeNow.toLocaleString()}
                sub={`Times shown in ${data.timezone}`}
              />
            </div>
          </div>

          <ActivityChart activity={data.activity} height={280} />

          <div className="tdash-grid-2">
            <BusyHoursHeatmap busyHours={data.busyHours} />
            <TierDonut tiers={data.tiers} />
          </div>

          <div className="tdash-grid-wide">
            <DashCard title="Top programs" meta="By sessions started">
              <ProgramList programs={data.topPrograms} />
            </DashCard>
            <GoalRing goal={data.weeklyGoal} />
          </div>
        </>
      ) : null}
    </>
  );
}
