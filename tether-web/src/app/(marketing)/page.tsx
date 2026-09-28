import Link from 'next/link';

const pillars = [
  {
    title: 'Member-first training',
    body: 'Give members structured workouts, clear progress, and a social layer that stays gym-specific.',
  },
  {
    title: 'Staff operations in one place',
    body: 'Manage roster approvals, notices, feed moderation, members, and gym settings from a single portal.',
  },
  {
    title: 'Built for real gym rollout',
    body: 'The mobile app, backend, and staff portal share one live data model instead of drifting into separate tools.',
  },
];

export default function HomePage() {
  return (
    <main className="page-shell">
      <div className="container" style={{ padding: '32px 0 72px', display: 'grid', gap: 56 }}>
        <header style={{ display: 'flex', justifyContent: 'space-between', gap: 20, alignItems: 'center' }}>
          <div style={{ color: 'var(--lime)', fontWeight: 800, letterSpacing: 1.6 }}>TETHER</div>
          <nav style={{ display: 'flex', gap: 18, alignItems: 'center' }}>
            <Link href="/features" style={{ color: 'var(--on-surface-variant)' }}>
              Features
            </Link>
            <Link href="/contact" style={{ color: 'var(--on-surface-variant)' }}>
              Contact
            </Link>
            <Link href="/login" style={buttonSecondaryStyle}>
              Staff Login
            </Link>
          </nav>
        </header>

        <section
          style={{
            display: 'grid',
            gap: 24,
            gridTemplateColumns: 'minmax(0, 1.15fr) minmax(320px, 0.85fr)',
            alignItems: 'center',
          }}
        >
          <div>
            <div style={{ color: 'var(--lime)', fontSize: 13, fontWeight: 700, letterSpacing: 1.2 }}>
              CONNECTED GYM PLATFORM
            </div>
            <h1 style={{ fontSize: 56, lineHeight: 1.02, margin: '14px 0 18px' }}>
              Operations for staff.
              <br />
              Momentum for members.
            </h1>
            <p style={{ color: 'var(--on-surface-variant)', fontSize: 18, maxWidth: 620, lineHeight: 1.6 }}>
              Tether combines a gym member app with a staff portal for roster control, notices, moderation,
              workouts, and member support.
            </p>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginTop: 28 }}>
              <Link href="/contact" style={buttonPrimaryStyle}>
                Talk To Us
              </Link>
              <Link href="/login" style={buttonSecondaryStyle}>
                Open Staff Portal
              </Link>
            </div>
          </div>

          <div
            style={{
              background: 'linear-gradient(180deg, rgba(195, 244, 0, 0.12), rgba(255,255,255,0.02))',
              border: '1px solid rgba(255,255,255,0.08)',
              borderRadius: 24,
              padding: 24,
              display: 'grid',
              gap: 14,
            }}
          >
            <div style={statCardStyle}>
              <div style={statLabelStyle}>ADMIN WORKSPACES</div>
              <div style={statValueStyle}>6+</div>
            </div>
            <div style={statCardStyle}>
              <div style={statLabelStyle}>LIVE MODULES</div>
              <div style={statValueStyle}>Members, Roster, Notices, Feed, Settings</div>
            </div>
            <div style={statCardStyle}>
              <div style={statLabelStyle}>ARCHITECTURE</div>
              <div style={{ fontSize: 18, fontWeight: 700 }}>Flutter app + NestJS API + Next staff portal</div>
            </div>
          </div>
        </section>

        <section style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(3, minmax(0, 1fr))' }}>
          {pillars.map((pillar) => (
            <article key={pillar.title} style={panelStyle}>
              <h2 style={{ margin: 0, fontSize: 22 }}>{pillar.title}</h2>
              <p style={{ margin: '10px 0 0', color: 'var(--on-surface-variant)', lineHeight: 1.6 }}>
                {pillar.body}
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

const statCardStyle: React.CSSProperties = {
  ...panelStyle,
  background: 'rgba(18, 19, 23, 0.72)',
};

const statLabelStyle: React.CSSProperties = {
  color: 'var(--on-surface-variant)',
  fontSize: 12,
  letterSpacing: 1,
};

const statValueStyle: React.CSSProperties = {
  marginTop: 10,
  fontSize: 24,
  fontWeight: 800,
};

const buttonPrimaryStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  height: 46,
  padding: '0 20px',
  borderRadius: 999,
  background: 'var(--lime)',
  color: 'var(--on-lime)',
  fontWeight: 700,
};

const buttonSecondaryStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  height: 46,
  padding: '0 20px',
  borderRadius: 999,
  background: 'var(--surface-high)',
  color: 'var(--on-surface)',
  border: '1px solid rgba(255,255,255,0.08)',
};
