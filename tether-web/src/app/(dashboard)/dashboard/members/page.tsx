import Link from 'next/link';
import { Search } from 'lucide-react';
import { apiFetch, type GymMember } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { initials, timeAgo } from '@/lib/format';
import { EmptyState, StatusPill } from '@/components/dashboard/ui';

const DAY_MS = 86_400_000;

type Activity = { label: string; tone: 'success' | 'warn' | 'neutral' | 'info' };

function activityStatus(member: GymMember, now: number): Activity {
  if (!member.lastWorkoutAt) {
    return now - new Date(member.createdAt).getTime() < 7 * DAY_MS
      ? { label: 'New', tone: 'info' }
      : { label: 'Inactive', tone: 'neutral' };
  }
  const since = now - new Date(member.lastWorkoutAt).getTime();
  if (since <= 7 * DAY_MS) return { label: 'Active', tone: 'success' };
  if (since <= 30 * DAY_MS) return { label: 'Lapsing', tone: 'warn' };
  return { label: 'Inactive', tone: 'neutral' };
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(new Date(value));
}

function titleCase(value: string) {
  return value.replace(/[_-]+/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

export default async function MembersPage({
  searchParams,
}: {
  searchParams?: Promise<{ q?: string; status?: string }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};
  const q = (params.q ?? '').trim();
  const statusFilter = params.status ?? '';

  let members: GymMember[] = [];
  let error: string | null = null;

  try {
    const path = q
      ? `/gyms/${session.gymId}/members?q=${encodeURIComponent(q)}`
      : `/gyms/${session.gymId}/members`;
    members = await apiFetch<GymMember[]>(path, {
      token: session.accessToken,
    });
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load members.';
  }

  const now = Date.now();
  const rows = members.map((member) => ({ member, activity: activityStatus(member, now) }));
  const counts = rows.reduce<Record<string, number>>((acc, row) => {
    acc[row.activity.label] = (acc[row.activity.label] ?? 0) + 1;
    return acc;
  }, {});
  const visible = statusFilter ? rows.filter((r) => r.activity.label === statusFilter) : rows;

  const filterHref = (status: string) => {
    const search = new URLSearchParams();
    if (q) search.set('q', q);
    if (status) search.set('status', status);
    const qs = search.toString();
    return qs ? `/dashboard/members?${qs}` : '/dashboard/members';
  };

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="tdash-page-title">Members</h1>
        <form method="get" className="tdash-search" role="search">
          <Search size={15} aria-hidden />
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Search name, email, phone"
            aria-label="Search members"
          />
          {statusFilter ? <input type="hidden" name="status" value={statusFilter} /> : null}
        </form>
      </div>

      <div className="row" style={{ gap: 8 }}>
        {['', 'Active', 'Lapsing', 'Inactive', 'New'].map((status) => (
          <Link
            key={status || 'all'}
            href={filterHref(status)}
            className={statusFilter === status ? 'chip chip-active' : 'chip'}
            style={{ display: 'inline-flex', alignItems: 'center' }}
          >
            {status || 'All'}
            <span className="tnum" style={{ marginLeft: 6, opacity: 0.6 }}>
              {status ? (counts[status] ?? 0) : rows.length}
            </span>
          </Link>
        ))}
        {q ? (
          <Link href="/dashboard/members" className="tdash-link" style={{ marginLeft: 4 }}>
            Clear search “{q}”
          </Link>
        ) : null}
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      {visible.length === 0 && !error ? (
        <EmptyState
          title={q || statusFilter ? 'No matches' : 'No members yet'}
          description={
            q || statusFilter
              ? 'Try another search or status filter.'
              : 'Add people from Roster, then they will appear here after signup.'
          }
          action={
            !q && !statusFilter ? (
              <Link href="/dashboard/roster" className="btn btn-primary">
                Open roster
              </Link>
            ) : undefined
          }
        />
      ) : (
        <div className="tdash-card" style={{ padding: 0, overflowX: 'auto' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th scope="col">Member</th>
                <th scope="col">Tier</th>
                <th scope="col">Status</th>
                <th scope="col">Last workout</th>
                <th scope="col">30-day workouts</th>
                <th scope="col">Joined</th>
              </tr>
            </thead>
            <tbody>
              {visible.map(({ member, activity }) => (
                <tr key={member.id}>
                  <td>
                    <Link
                      href={`/dashboard/members/${member.id}`}
                      className="row"
                      style={{ gap: 10, flexWrap: 'nowrap', fontWeight: 600 }}
                    >
                      <span className="avatar-chip">
                        {initials(member.displayName || member.email)}
                      </span>
                      <span style={{ minWidth: 0 }}>
                        {member.displayName || 'Unnamed member'}
                        <div className="muted" style={{ fontWeight: 400, fontSize: 12 }}>
                          {member.email || member.phone || 'No contact info'}
                        </div>
                      </span>
                    </Link>
                  </td>
                  <td className="muted">{titleCase(member.subscriptionTier || 'free')}</td>
                  <td>
                    <StatusPill tone={activity.tone}>{activity.label}</StatusPill>
                  </td>
                  <td className="muted">
                    {member.lastWorkoutAt ? timeAgo(member.lastWorkoutAt) : 'Never'}
                  </td>
                  <td className="tnum">{member.workoutsLast30Days}</td>
                  <td className="muted">{formatDate(member.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
