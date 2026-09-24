import Link from 'next/link';
import { ArrowLeft, Bell, LogOut, Plus } from 'lucide-react';
import { logoutStaff } from './actions';
import { requireStaffSession } from '@/lib/auth';
import { apiFetch, type GymSettings, type GymStats } from '@/lib/api';
import { MotionProvider } from '@/components/dashboard/motion-provider';
import { DashboardNav, SettingsNavLink } from './dashboard-nav';

function greeting(timeZone: string) {
  let hour: number;
  try {
    hour = Number(
      new Intl.DateTimeFormat('en-GB', { timeZone, hour: '2-digit', hourCycle: 'h23' }).format(
        new Date(),
      ),
    );
  } catch {
    hour = new Date().getHours();
  }
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

function displayName(email: string) {
  const local = email.split('@')[0] ?? '';
  const first = local.split(/[._-]/)[0] || local;
  return first ? first[0]!.toUpperCase() + first.slice(1) : 'there';
}

export default async function DashboardLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const session = await requireStaffSession();

  const [gym, stats] = await Promise.all([
    apiFetch<GymSettings>(`/gyms/${session.gymId}/settings`, {
      token: session.accessToken,
    }).catch(() => null),
    apiFetch<GymStats>(`/gyms/${session.gymId}/stats`, {
      token: session.accessToken,
    }).catch(() => null),
  ]);

  const pending = stats?.pendingCount ?? 0;
  const flagged = stats?.flaggedCount ?? 0;
  const needsAttention = pending + flagged;
  const bellLabel =
    needsAttention === 0
      ? 'Nothing needs attention'
      : `${pending} pending approval${pending === 1 ? '' : 's'}, ${flagged} flagged post${flagged === 1 ? '' : 's'}`;
  const name = displayName(session.email);

  return (
    <MotionProvider>
      <div className="tdash">
        <div className="tdash-shell">
          <aside className="tdash-rail">
            <Link href="/dashboard" className="tdash-brand">
              <span className="tdash-brand-mark" aria-hidden>
                T
              </span>
              <span className="tdash-brand-text">
                <strong>Tether</strong>
                <span>{gym?.name ?? 'Your gym'}</span>
              </span>
            </Link>

            <DashboardNav />

            <div className="tdash-rail-footer">
              <SettingsNavLink />
              <form action={logoutStaff}>
                <button
                  type="submit"
                  className="tdash-nav-link"
                  style={{ width: '100%', border: 0, background: 'transparent', cursor: 'pointer' }}
                  title="Log out"
                >
                  <LogOut size={18} strokeWidth={1.75} aria-hidden />
                  <span className="tdash-nav-label">Log out</span>
                </button>
              </form>
              <Link href="/" className="tdash-nav-link" title="Back to site">
                <ArrowLeft size={18} strokeWidth={1.75} aria-hidden />
                <span className="tdash-nav-label">Back to site</span>
              </Link>
            </div>
          </aside>

          <main className="tdash-main">
            <header className="tdash-topbar">
              <div className="tdash-greeting">
                <strong>
                  {greeting(gym?.timezone ?? 'UTC')}, {name}
                </strong>
                <span>Here is {gym?.name ?? 'your gym'} at a glance</span>
              </div>
              <Link href="/dashboard/roster" className="btn btn-primary">
                <Plus size={14} aria-hidden /> Add member
              </Link>
              <Link
                href={pending > 0 || flagged === 0 ? '/dashboard/roster' : '/dashboard/feed'}
                className="tdash-icon-btn"
                aria-label={bellLabel}
                title={bellLabel}
              >
                <Bell size={18} aria-hidden />
                {needsAttention > 0 ? <span className="tdash-dot" aria-hidden /> : null}
              </Link>
              <span className="tdash-avatar" title={session.email} aria-label={`Signed in as ${session.email}`}>
                {name.slice(0, 1)}
              </span>
            </header>
            {children}
          </main>
        </div>
      </div>
    </MotionProvider>
  );
}
