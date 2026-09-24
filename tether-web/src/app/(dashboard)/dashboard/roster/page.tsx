import { apiFetch, type PendingRosterEntry } from '@/lib/api';
import { requireStaffSession } from '@/lib/auth';
import { EmptyState, PageHeader, StatusPill } from '@/components/dashboard/ui';
import {
  addRosterEntry,
  approveRosterEntry,
  importRosterCsv,
} from './actions';

function formatDate(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

export default async function RosterPage({
  searchParams,
}: {
  searchParams?: Promise<{
    error?: string;
    message?: string;
    importErrors?: string;
  }>;
}) {
  const session = await requireStaffSession();
  const params = (await searchParams) ?? {};

  let pending: PendingRosterEntry[] = [];
  let error: string | null = null;

  try {
    pending = await apiFetch<PendingRosterEntry[]>(
      `/roster/pending/${session.gymId}`,
      { token: session.accessToken },
    );
  } catch (err) {
    error = err instanceof Error ? err.message : 'Failed to load pending roster.';
  }

  const importErrorLines = params.importErrors
    ? params.importErrors.split(' · ').filter(Boolean)
    : [];

  return (
    <>
      <PageHeader
        kicker="Roster"
        title="Roster"
        subtitle="Add members manually, import a CSV, and approve pending signup requests."
      />

      {params.message ? <div className="alert alert-success">{params.message}</div> : null}

      {importErrorLines.length > 0 ? (
        <div className="alert alert-error stack">
          <strong>Import row errors</strong>
          <ul style={{ margin: 0, paddingLeft: 18 }}>
            {importErrorLines.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        </div>
      ) : null}

      {error || params.error ? (
        <div className="alert alert-error">{params.error ?? error}</div>
      ) : null}

      <div className="two-col">
        <section className="panel">
          <h2 className="panel-title">Add member</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            At least an email or phone is required.
          </p>
          <form action={addRosterEntry} className="stack" style={{ marginTop: 14 }}>
            <input name="memberName" placeholder="Member name" className="field" />
            <input name="email" type="email" placeholder="Email" className="field" />
            <input name="phone" placeholder="Phone" className="field" />
            <input
              name="externalMemberId"
              placeholder="External member ID"
              className="field"
            />
            <button type="submit" className="btn btn-primary">
              Save entry
            </button>
          </form>
        </section>

        <section className="panel">
          <h2 className="panel-title">Import CSV</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            Include headers such as <code>email</code>, <code>phone</code>,{' '}
            <code>member_name</code>, <code>external_member_id</code>.
          </p>
          <form action={importRosterCsv} className="stack" style={{ marginTop: 14 }}>
            <textarea
              name="csvContent"
              className="field"
              placeholder={
                'email,phone,member_name,external_member_id\nmember@example.com,,Jane Smith,M-1001'
              }
            />
            <button type="submit" className="btn btn-primary">
              Import CSV
            </button>
          </form>
        </section>
      </div>

      <section className="panel">
        <div className="row" style={{ justifyContent: 'space-between', marginBottom: 14 }}>
          <h2 className="panel-title" style={{ margin: 0 }}>
            Pending approvals
          </h2>
          <span className="muted" style={{ fontSize: 14 }}>
            <StatusPill tone={pending.length > 0 ? 'warn' : 'success'}>
              {pending.length} pending
            </StatusPill>
          </span>
        </div>

        {pending.length === 0 ? (
          <EmptyState
            title="All clear"
            description="No pending signup requests right now."
          />
        ) : (
          <div className="stack">
            {pending.map((entry) => (
              <div
                key={entry.id}
                className="row"
                style={{
                  justifyContent: 'space-between',
                  border: '1px solid var(--border)',
                  background: 'var(--surface-high)',
                  borderRadius: 14,
                  padding: 14,
                }}
              >
                <div>
                  <div style={{ fontWeight: 700 }}>
                    {entry.memberName || 'Pending member'}
                  </div>
                  <div className="muted" style={{ marginTop: 4 }}>
                    {entry.email || entry.phone || 'No contact info'}
                  </div>
                  <div className="muted" style={{ marginTop: 4, fontSize: 12 }}>
                    Requested {formatDate(entry.createdAt)}
                  </div>
                </div>

                <form action={approveRosterEntry}>
                  <input type="hidden" name="rosterId" value={entry.id} />
                  <button type="submit" className="btn btn-primary">
                    Approve
                  </button>
                </form>
              </div>
            ))}
          </div>
        )}
      </section>
    </>
  );
}
