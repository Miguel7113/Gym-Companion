import Link from 'next/link';
import { apiFetch, type ModerationPost } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { initials } from '@/lib/format';
import { DashCard, EmptyState } from '@/components/dashboard/ui';
import { FeedCard } from '@/components/dashboard/feed-card';

export default async function FeedPage({
  searchParams,
}: {
  searchParams?: Promise<{ error?: string; message?: string }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};

  let flagged: ModerationPost[] = [];
  let recent: ModerationPost[] = [];
  let error: string | null = null;

  try {
    [flagged, recent] = await Promise.all([
      apiFetch<ModerationPost[]>('/staff/social/flagged', { token: session.accessToken }),
      apiFetch<ModerationPost[]>('/staff/social/recent?limit=30', { token: session.accessToken }),
    ]);
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load the feed.';
  }

  const flaggedIds = new Set(flagged.map((p) => p.id));
  const unflagged = recent.filter((p) => !flaggedIds.has(p.id));

  return (
    <div className="flex w-full max-w-[720px] flex-col gap-3">
      <h1 className="tdash-page-title">Community feed</h1>

      {params.message ? <div className="alert alert-success">{params.message}</div> : null}
      {error || params.error ? (
        <div className="alert alert-error">{params.error ?? error}</div>
      ) : null}

      <div className="tdash-card" style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
        <span className="avatar-chip" aria-hidden>
          {initials(session.email.split('@')[0])}
        </span>
        <Link href="/dashboard/notices?mode=new" className="tdash-composer">
          Announce something to your members…
        </Link>
        <Link href="/dashboard/notices?mode=new" className="btn btn-primary">
          Post notice
        </Link>
      </div>

      {flagged.length > 0 ? (
        <DashCard title="Needs review" meta={`${flagged.length} flagged`}>
          <div className="flex flex-col gap-5">
            {flagged.map((post) => (
              <FeedCard key={post.id} post={post} returnTo="/dashboard/feed" showFlagActions />
            ))}
          </div>
        </DashCard>
      ) : null}

      {unflagged.length === 0 && flagged.length === 0 && !error ? (
        <EmptyState
          title="No posts yet"
          description="When members share workouts or post updates, they show up here."
        />
      ) : (
        unflagged.map((post) => (
          <div key={post.id} className="tdash-card card-lift">
            <FeedCard post={post} returnTo="/dashboard/feed" />
          </div>
        ))
      )}
    </div>
  );
}
