import Link from 'next/link';
import type { ReactNode } from 'react';
import type { DashboardRange, GymDashboard } from '@/lib/api';
import { initials, timeAgo } from '@/lib/format';

export function PageHeader({
  kicker,
  title,
  subtitle,
  actions,
}: {
  kicker: string;
  title: string;
  subtitle?: string;
  actions?: ReactNode;
}) {
  return (
    <div className="dashboard-topbar">
      <header>
        <p className="page-kicker">{kicker}</p>
        <h1 className="page-title">{title}</h1>
        {subtitle ? <p className="page-subtitle">{subtitle}</p> : null}
      </header>
      {actions ? <div className="row">{actions}</div> : null}
    </div>
  );
}

export function Panel({
  title,
  children,
  className = '',
  action,
}: {
  title?: string;
  children: ReactNode;
  className?: string;
  action?: ReactNode;
}) {
  return (
    <section className={`panel ${className}`.trim()}>
      {title || action ? (
        <div className="row" style={{ justifyContent: 'space-between', marginBottom: 14 }}>
          {title ? <h2 className="panel-title" style={{ margin: 0 }}>{title}</h2> : <span />}
          {action}
        </div>
      ) : null}
      {children}
    </section>
  );
}

export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="empty-state">
      <strong>{title}</strong>
      <span className="muted">{description}</span>
      {action}
    </div>
  );
}

export function StatusPill({
  children,
  tone = 'success',
}: {
  children: ReactNode;
  tone?: 'success' | 'neutral' | 'danger' | 'warn' | 'info';
}) {
  const className =
    tone === 'danger'
      ? 'status-pill status-pill-danger'
      : tone === 'warn'
        ? 'status-pill status-pill-warn'
        : tone === 'neutral'
          ? 'status-pill status-pill-neutral'
          : tone === 'info'
            ? 'status-pill status-pill-info'
            : 'status-pill';
  return <span className={className}>{children}</span>;
}

export function DashCard({
  title,
  meta,
  action,
  children,
  className = '',
}: {
  title: string;
  meta?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`tdash-card card-lift ${className}`.trim()}>
      <div className="tdash-card-head">
        <h2 className="tdash-card-title">{title}</h2>
        {action ?? (meta ? <span className="tdash-card-meta">{meta}</span> : null)}
      </div>
      {children}
    </section>
  );
}

const RANGES: Array<{ value: DashboardRange; label: string }> = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: 'This week' },
  { value: 'month', label: 'This month' },
];

export function RangeTabs({ basePath, current }: { basePath: string; current: DashboardRange }) {
  return (
    <nav className="tdash-range" aria-label="Time range">
      {RANGES.map((range) => (
        <Link
          key={range.value}
          href={range.value === 'week' ? basePath : `${basePath}?range=${range.value}`}
          aria-current={range.value === current ? 'page' : undefined}
          scroll={false}
        >
          {range.label}
        </Link>
      ))}
    </nav>
  );
}

export function PendingList({ entries }: { entries: GymDashboard['pendingRoster'] }) {
  if (entries.length === 0) {
    return <p className="tdash-empty">No one is waiting for approval.</p>;
  }
  return (
    <ul className="m-0 flex list-none flex-col gap-2.5 p-0">
      {entries.map((entry) => (
        <li key={entry.id} className="flex items-center gap-2.5">
          <span className="flex h-[30px] w-[30px] shrink-0 items-center justify-center rounded-full bg-surface-muted text-[11px] font-medium text-neutral-300">
            {initials(entry.name)}
          </span>
          <div className="min-w-0 flex-1">
            <div className="truncate text-[13px] font-medium">{entry.name}</div>
            <div className="truncate text-xs text-neutral-400">
              Requested {timeAgo(entry.createdAt)}
              {entry.contact && entry.contact !== entry.name ? ` · ${entry.contact}` : ''}
            </div>
          </div>
          <StatusPill tone="warn">Pending</StatusPill>
        </li>
      ))}
    </ul>
  );
}
