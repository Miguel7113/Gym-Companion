import Link from 'next/link';
import { apiFetch, type StaffMemberProfile } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { EmptyState, StatusPill } from '@/components/dashboard/ui';
import { sendPasswordReset, updateMember } from './actions';

function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

export default async function MemberDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ memberId: string }>;
  searchParams?: Promise<{ error?: string; message?: string }>;
}) {
  const session = await requireStaffSession();
  const { memberId } = await params;
  const query = (await searchParams) ?? {};

  let profile: StaffMemberProfile | null = null;
  let error: string | null = null;

  try {
    profile = await apiFetch<StaffMemberProfile>(
      `/staff/members/${memberId}/profile`,
      {
        token: session.accessToken,
      },
    );
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load member profile.';
  }

  return (
    <>
      <div className="row" style={{ justifyContent: 'space-between', alignItems: 'start' }}>
        <div>
          <Link href="/dashboard/members" className="btn btn-ghost">
            ← Back to members
          </Link>
          <h1 className="page-title" style={{ marginTop: 10 }}>
            {profile?.displayName ?? 'Member profile'}
          </h1>
          <p className="page-subtitle">
            Member details, recent posts, and account actions for support.
          </p>
        </div>
        {profile?.staffRole ? (
          <StatusPill>{profile.staffRole.toUpperCase()}</StatusPill>
        ) : null}
      </div>

      {query.message ? <div className="alert alert-success">{query.message}</div> : null}
      {error || query.error ? (
        <div className="alert alert-error">{query.error ?? error}</div>
      ) : null}

      {profile ? (
        <>
          <div className="stat-grid-4">
            <StatCard label="Workouts" value={String(profile.stats.workoutCount)} />
            <StatCard label="Total Sets" value={String(profile.stats.totalSets)} />
            <StatCard
              label="Volume (kg)"
              value={String(Math.round(profile.stats.totalVolume))}
            />
            <StatCard label="Streak" value={`${profile.stats.streakDays} days`} />
          </div>

          <div className="two-col-wide">
            <section className="panel">
              <h2 className="panel-title">Recent posts</h2>
              {profile.posts.length === 0 ? (
                <EmptyState
                  title="No shared posts"
                  description="This member has not posted to the gym feed yet."
                />
              ) : (
                <div className="stack" style={{ marginTop: 12 }}>
                  {profile.posts.map((post) => (
                    <article key={post.id} className="list-item">
                      <div className="row" style={{ justifyContent: 'space-between' }}>
                        <div style={{ fontWeight: 700 }}>{post.authorName}</div>
                        <div className="muted" style={{ fontSize: 12 }}>
                          {formatDate(post.createdAt)}
                        </div>
                      </div>
                      <div style={{ marginTop: 10 }}>{post.content || '(No text content)'}</div>
                      <div className="row muted" style={{ marginTop: 10, fontSize: 13 }}>
                        <span>{post.likeCount} likes</span>
                        <span>{post.commentCount} comments</span>
                        <span>{post.achievementType || 'general post'}</span>
                        {post.coachCertification ? (
                          <span>Certified by {post.coachCertification.coachName}</span>
                        ) : null}
                      </div>
                    </article>
                  ))}
                </div>
              )}
            </section>

            <section className="stack" style={{ gap: 16 }}>
              <div className="panel">
                <h2 className="panel-title">Profile</h2>
                <form action={updateMember} className="stack" style={{ marginTop: 12 }}>
                  <input type="hidden" name="memberId" value={profile.memberId} />
                  <Field label="Member ID">
                    <div className="field-static mono">{profile.memberId}</div>
                  </Field>
                  <Field label="Display name">
                    <input
                      className="field"
                      name="displayName"
                      defaultValue={profile.displayName}
                    />
                  </Field>
                  <Field label="Email">
                    <input
                      className="field"
                      name="email"
                      type="email"
                      defaultValue={profile.email ?? ''}
                    />
                  </Field>
                  <Field label="Phone">
                    <input className="field" name="phone" defaultValue={profile.phone ?? ''} />
                  </Field>
                  <Field label="Subscription tier">
                    <input
                      className="field"
                      name="subscriptionTier"
                      defaultValue={profile.subscriptionTier}
                      required
                    />
                  </Field>
                  <Field label="Staff role">
                    <div className="field-static">{profile.staffRole ?? 'Member'}</div>
                  </Field>
                  <Field label="Gym">
                    <div className="field-static">{profile.gym.name}</div>
                  </Field>
                  <button type="submit" className="btn btn-primary">
                    Save member
                  </button>
                </form>
                <form action={sendPasswordReset} style={{ marginTop: 12 }}>
                  <input type="hidden" name="memberId" value={profile.memberId} />
                  <button type="submit" className="btn btn-secondary" style={{ width: '100%' }}>
                    Send password reset
                  </button>
                </form>
              </div>

              <div className="panel">
                <h2 className="panel-title">Shared routines</h2>
                {profile.sharedRoutines.length === 0 ? (
                  <EmptyState
                    title="No shared routines"
                    description="Member-created routines will show here."
                  />
                ) : (
                  <div className="stack" style={{ marginTop: 12 }}>
                    {profile.sharedRoutines.map((routine) => (
                      <div key={routine.id} className="list-item">
                        <div style={{ fontWeight: 700 }}>{routine.name}</div>
                        <div className="muted" style={{ fontSize: 13, marginTop: 6 }}>
                          {routine.difficulty || 'No difficulty set'} · Updated{' '}
                          {formatDate(routine.updatedAt)}
                        </div>
                        <div className="muted" style={{ marginTop: 10, fontSize: 13 }}>
                          {routine.exercises.map((item) => item.exercise.name).join(', ') ||
                            'No exercises'}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </section>
          </div>
        </>
      ) : null}
    </>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="stat-card">
      <div className="stat-label">{label}</div>
      <div className="stat-value" style={{ fontSize: 28 }}>
        {value}
      </div>
    </div>
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
