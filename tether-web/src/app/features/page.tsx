import Link from 'next/link';

const items = [
  {
    title: 'Staff Portal',
    body: 'Live dashboard, member profiles, roster workflows, notices, feed moderation, and settings.',
  },
  {
    title: 'Member App',
    body: 'Workouts, routines, progress, gym notices, and a gym-wide social feed built for member engagement.',
  },
  {
    title: 'Shared Backend',
    body: 'One NestJS API and one Postgres/Supabase data model for both staff and member experiences.',
  },
];

export default function FeaturesPage() {
  return (
    <main className="page-shell">
      <div className="container" style={{ padding: '32px 0 72px', display: 'grid', gap: 32 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 20, alignItems: 'center' }}>
          <Link href="/" style={{ color: 'var(--lime)', fontWeight: 800, letterSpacing: 1.4 }}>
            TETHER
          </Link>
          <Link href="/login" style={buttonStyle}>
            Staff Login
          </Link>
        </div>

        <div>
          <div style={{ color: 'var(--lime)', fontSize: 13, fontWeight: 700, letterSpacing: 1.2 }}>
            FEATURES
          </div>
          <h1 style={{ fontSize: 44, margin: '12px 0 0' }}>Everything needed to run the gym and support the member journey.</h1>
        </div>

        <section style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(3, minmax(0, 1fr))' }}>
          {items.map((item) => (
            <article key={item.title} style={panelStyle}>
              <h2 style={{ margin: 0, fontSize: 24 }}>{item.title}</h2>
              <p style={{ margin: '10px 0 0', color: 'var(--on-surface-variant)', lineHeight: 1.6 }}>
                {item.body}
              </p>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}

const panelStyle: React.CSSProperties = {
  background: 'var(--surface-card)',
  border: '1px solid rgba(255,255,255,0.08)',
  borderRadius: 20,
  padding: 22,
};

const buttonStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  height: 44,
  padding: '0 18px',
  borderRadius: 999,
  background: 'var(--surface-high)',
  color: 'var(--on-surface)',
  border: '1px solid rgba(255,255,255,0.08)',
};
