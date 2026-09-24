import Link from 'next/link';
import { apiFetch, type StaffNotice } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { EmptyState, PageHeader, StatusPill } from '@/components/dashboard/ui';
import {
  createNotice,
  restoreNotice,
  softDeleteNotice,
  updateNotice,
} from './actions';

const NOTICE_TAGS = ['ANNOUNCEMENT', 'CLASS_UPDATE', 'REMINDER', 'EVENT'] as const;

type SearchParams = {
  noticeId?: string;
  q?: string;
  filter?: 'all' | 'pinned' | 'deleted';
  mode?: 'new';
  error?: string;
  message?: string;
};

function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

function tagLabel(tag: string) {
  return tag === 'CLASS_UPDATE' ? 'CLASS UPDATE' : tag;
}

function authorLabel(notice: StaffNotice) {
  return (
    notice.authorUser?.displayName ||
    notice.authorStaff?.email ||
    'Unknown author'
  );
}

export default async function NoticesPage({
  searchParams,
}: {
  searchParams?: Promise<SearchParams>;
}) {
  const params = (await searchParams) ?? {};
  const session = await requireStaffSession();

  let notices: StaffNotice[] = [];
  let error: string | null = null;

  try {
    notices = await apiFetch<StaffNotice[]>('/staff/notices?includeDeleted=true', {
      token: session.accessToken,
    });
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load notices.';
  }

  const filter = params.filter ?? 'all';
  const query = (params.q ?? '').trim().toLowerCase();
  const filtered = notices.filter((notice) => {
    if (filter === 'pinned' && !notice.isPinned) return false;
    if (filter === 'deleted' && !notice.deletedAt) return false;
    if (filter !== 'deleted' && notice.deletedAt && filter !== 'all') return false;
    if (!query) return true;
    const haystack = `${notice.title} ${notice.body} ${notice.tag}`.toLowerCase();
    return haystack.includes(query);
  });

  const selected =
    params.mode === 'new'
      ? null
      : filtered.find((notice) => notice.id === params.noticeId) ?? filtered[0] ?? null;

  const counts = {
    all: notices.length,
    pinned: notices.filter((n) => n.isPinned && !n.deletedAt).length,
    deleted: notices.filter((n) => n.deletedAt).length,
  };

  return (
    <>
      <PageHeader
        kicker="Notices"
        title="Notices"
        subtitle="Create, edit, pin, and restore gym announcements for members."
        actions={
          <Link href="/dashboard/notices?mode=new" className="btn btn-primary">
            New notice
          </Link>
        }
      />

      {params.message ? <div className="alert alert-success">{params.message}</div> : null}
      {error || params.error ? (
        <div className="alert alert-error">{params.error ?? error}</div>
      ) : null}

      <div className="notices-split">
        <section className="panel">
          <div>
            <h2 className="panel-title">Notice list</h2>
            <p className="muted" style={{ margin: '4px 0 0', fontSize: 13 }}>
              Pinned first. Deleted items can be restored.
            </p>
          </div>

          <form method="get" action="/dashboard/notices" className="stack" style={{ marginTop: 14 }}>
            <input
              className="field"
              name="q"
              defaultValue={params.q ?? ''}
              placeholder="Search notices"
            />
            <div className="row">
              {(['all', 'pinned', 'deleted'] as const).map((value) => (
                <button
                  key={value}
                  type="submit"
                  name="filter"
                  value={value}
                  className={filter === value ? 'chip chip-active' : 'chip'}
                >
                  {value.toUpperCase()} ({counts[value]})
                </button>
              ))}
            </div>
          </form>

          <div className="stack" style={{ marginTop: 16 }}>
            {filtered.length === 0 ? (
              <EmptyState
                title="No notices here"
                description="Try another filter or create a new notice."
              />
            ) : (
              filtered.map((notice) => {
                const href = `/dashboard/notices?noticeId=${notice.id}&filter=${filter}${
                  params.q ? `&q=${encodeURIComponent(params.q)}` : ''
                }`;
                const isSelected = selected?.id === notice.id && params.mode !== 'new';
                return (
                  <Link
                    key={notice.id}
                    href={href}
                    className={isSelected ? 'list-item list-item-selected' : 'list-item'}
                  >
                    <div className="row" style={{ justifyContent: 'space-between' }}>
                      <div style={{ fontWeight: 700, lineHeight: 1.35 }}>{notice.title}</div>
                      {notice.isPinned ? <StatusPill>PINNED</StatusPill> : null}
                    </div>
                    <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>
                      {tagLabel(notice.tag)} · {authorLabel(notice)}
                    </div>
                    <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>
                      {notice.deletedAt ? 'Deleted' : formatDate(notice.publishedAt)}
                    </div>
                  </Link>
                );
              })
            )}
          </div>
        </section>

        <section className="panel">
          {params.mode === 'new' || !selected ? (
            <NoticeEditor
              heading="Create notice"
              description="Post a new gym notice to Home and the Notices screen."
              action={createNotice}
              submitLabel="Create notice"
            />
          ) : (
            <div className="stack" style={{ gap: 18 }}>
              <NoticeEditor
                heading="Edit notice"
                description={`Last updated ${formatDate(selected.updatedAt)}`}
                action={updateNotice}
                submitLabel="Save changes"
                notice={selected}
              />

              <div className="row">
                {selected.deletedAt ? (
                  <form action={restoreNotice}>
                    <input type="hidden" name="noticeId" value={selected.id} />
                    <button type="submit" className="btn btn-primary">
                      Restore notice
                    </button>
                  </form>
                ) : (
                  <form action={softDeleteNotice}>
                    <input type="hidden" name="noticeId" value={selected.id} />
                    <button type="submit" className="btn btn-danger">
                      Soft delete
                    </button>
                  </form>
                )}

                <Link href="/dashboard/notices?mode=new" className="btn btn-secondary">
                  New notice
                </Link>
              </div>
            </div>
          )}
        </section>
      </div>
    </>
  );
}

function NoticeEditor({
  heading,
  description,
  action,
  submitLabel,
  notice,
}: {
  heading: string;
  description: string;
  action: (formData: FormData) => void | Promise<void>;
  submitLabel: string;
  notice?: StaffNotice;
}) {
  return (
    <form action={action} className="stack" style={{ gap: 14 }}>
      <div>
        <h2 className="panel-title">{heading}</h2>
        <p className="muted" style={{ margin: '6px 0 0' }}>
          {description}
        </p>
      </div>

      {notice ? <input type="hidden" name="noticeId" value={notice.id} /> : null}

      <label className="stack" style={{ gap: 8 }}>
        <span className="field-label">Title</span>
        <input
          className="field"
          name="title"
          defaultValue={notice?.title ?? ''}
          maxLength={120}
          required
        />
      </label>

      <label className="stack" style={{ gap: 8 }}>
        <span className="field-label">Tag</span>
        <select className="field" name="tag" defaultValue={notice?.tag ?? 'ANNOUNCEMENT'}>
          {NOTICE_TAGS.map((tag) => (
            <option key={tag} value={tag}>
              {tagLabel(tag)}
            </option>
          ))}
        </select>
      </label>

      <label className="stack" style={{ gap: 8 }}>
        <span className="field-label">Body</span>
        <textarea
          className="field"
          name="body"
          defaultValue={notice?.body ?? ''}
          style={{ minHeight: 220 }}
          maxLength={4000}
          required
        />
      </label>

      <label className="row muted">
        <input type="checkbox" name="isPinned" defaultChecked={notice?.isPinned ?? false} />
        <span>Pin this notice to the top</span>
      </label>

      <button type="submit" className="btn btn-primary">
        {submitLabel}
      </button>
    </form>
  );
}
