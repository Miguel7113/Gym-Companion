import {
  apiFetch,
  type GymSettings,
  type GymStaffMember,
  type GymStats,
} from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { EmptyState, PageHeader, Panel, StatusPill } from '@/components/dashboard/ui';
import { inviteStaff, updateGymSettings, updateStaffRole } from './actions';

export default async function SettingsPage({
  searchParams,
}: {
  searchParams?: Promise<{ error?: string; message?: string }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};

  let gym: GymSettings | null = null;
  let staffMembers: GymStaffMember[] = [];
  let stats: GymStats | null = null;
  let error: string | null = null;

  try {
    [gym, stats, staffMembers] = await Promise.all([
      apiFetch<GymSettings>(`/gyms/${session.gymId}/settings`, {
        token: session.accessToken,
      }),
      apiFetch<GymStats>(`/gyms/${session.gymId}/stats`, {
        token: session.accessToken,
      }),
      apiFetch<GymStaffMember[]>('/auth/staff', {
        token: session.accessToken,
      }),
    ]);
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load gym settings.';
  }

  return (
    <>
      <PageHeader
        kicker="Settings"
        title="Settings"
        subtitle="Update gym profile details and manage staff accounts for this location."
      />

      {params.message ? <div className="alert alert-success">{params.message}</div> : null}
      {error || params.error ? (
        <div className="alert alert-error">{params.error ?? error}</div>
      ) : null}

      <div className="two-col-wide">
        <Panel title="Gym profile">
          <form action={updateGymSettings} className="stack" style={{ gap: 14 }}>
            <Field label="Gym name">
              <input className="field" name="name" defaultValue={gym?.name ?? ''} required />
            </Field>
            <Field label="Gym ID">
              <div className="field-static mono">{gym?.id ?? session.gymId}</div>
            </Field>
            <Field label="Primary color">
              <input
                className="field"
                name="primaryColor"
                defaultValue={gym?.primaryColor ?? '#C3F400'}
                placeholder="#C3F400"
              />
            </Field>
            <Field label="Logo URL">
              <input
                className="field"
                name="logoUrl"
                defaultValue={gym?.logoUrl ?? ''}
                placeholder="https://..."
              />
            </Field>
            <Field label="Timezone">
              <input
                className="field"
                name="timezone"
                defaultValue={gym?.timezone ?? 'UTC'}
                placeholder="Europe/London"
                required
              />
            </Field>
            <Field label="Contact email">
              <input
                className="field"
                name="contactEmail"
                type="email"
                defaultValue={gym?.contactEmail ?? ''}
                placeholder="team@gym.com"
              />
            </Field>
            <Field label="Subscription tier">
              <input
                className="field"
                name="subscriptionTier"
                defaultValue={gym?.subscriptionTier ?? 'trial'}
                required
              />
            </Field>
            <button type="submit" className="btn btn-primary">
              Save settings
            </button>
          </form>
        </Panel>

        <Panel title="Operational snapshot">
          <div className="stack">
            <StatRow label="Members" value={String(stats?.memberCount ?? '--')} />
            <StatRow label="Workouts this week" value={String(stats?.workoutsThisWeek ?? '--')} />
            <StatRow
              label="Pending roster approvals"
              value={String(stats?.pendingCount ?? '--')}
            />
          </div>
        </Panel>
      </div>

      <Panel title="Status">
        <div className="stack" style={{ gap: 14 }}>
          <Field label="Portal access">
            <div className="field-static">Staff-authenticated</div>
          </Field>
          <Field label="Gym status">
            <div className="field-static row" style={{ justifyContent: 'space-between' }}>
              <span>{gym?.isActive ? 'Active' : 'Inactive'}</span>
              <StatusPill tone={gym?.isActive ? 'success' : 'danger'}>
                {gym?.isActive ? 'Live' : 'Off'}
              </StatusPill>
            </div>
          </Field>
          <Field label="Last updated">
            <div className="field-static">{gym ? formatDate(gym.updatedAt) : '--'}</div>
          </Field>
        </div>
      </Panel>

      <Panel title="Staff access">
        <div className="two-col-wide">
          <div className="stack">
            {staffMembers.length === 0 ? (
              <EmptyState
                title="No staff yet"
                description="Create a coach or admin account on the right."
              />
            ) : (
              staffMembers.map((staffMember) => (
                <form key={staffMember.id} action={updateStaffRole} className="list-item stack">
                  <input type="hidden" name="staffId" value={staffMember.id} />
                  <div style={{ fontWeight: 700 }}>{staffMember.email}</div>
                  <div className="muted" style={{ fontSize: 13 }}>
                    {staffMember.authProviderId
                      ? 'Linked to auth user'
                      : 'Pending auth link on first login'}
                  </div>
                  <div className="row">
                    <select
                      className="field"
                      name="role"
                      defaultValue={staffMember.role}
                      style={{ flex: 1 }}
                    >
                      <option value="admin">Admin</option>
                      <option value="coach">Coach</option>
                    </select>
                    <button type="submit" className="btn btn-secondary">
                      Update role
                    </button>
                  </div>
                </form>
              ))
            )}
          </div>

          <form action={inviteStaff} className="stack" style={{ gap: 12 }}>
            <Field label="New staff email">
              <input
                className="field"
                name="email"
                type="email"
                placeholder="coach@gym.com"
                required
              />
            </Field>
            <Field label="Temporary password">
              <input className="field" name="password" type="password" minLength={6} required />
            </Field>
            <Field label="Role">
              <select className="field" name="role" defaultValue="coach">
                <option value="coach">Coach</option>
                <option value="admin">Admin</option>
              </select>
            </Field>
            <button type="submit" className="btn btn-primary">
              Create staff account
            </button>
          </form>
        </div>
      </Panel>
    </>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="stack" style={{ gap: 8 }}>
      <div className="field-label">{label}</div>
      {children}
    </div>
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

function StatRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="list-item row" style={{ justifyContent: 'space-between' }}>
      <span className="muted">{label}</span>
      <strong style={{ fontFamily: 'var(--font-display)', fontSize: 22 }}>{value}</strong>
    </div>
  );
}
