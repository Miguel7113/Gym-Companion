import Link from 'next/link';

export default function ContactPage() {
  return (
    <main className="page-shell">
      <div className="container" style={{ padding: '32px 0 72px', display: 'grid', gap: 28 }}>
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
            CONTACT
          </div>
          <h1 style={{ fontSize: 44, margin: '12px 0 0' }}>Bring Tether into your gym.</h1>
          <p style={{ color: 'var(--on-surface-variant)', fontSize: 18, maxWidth: 640, lineHeight: 1.6 }}>
            Tether is built for gyms that want one connected system for staff operations and member engagement.
          </p>
        </div>

        <section
          style={{
            background: 'var(--surface-card)',
            border: '1px solid rgba(255,255,255,0.08)',
            borderRadius: 20,
            padding: 24,
            display: 'grid',
            gap: 12,
          }}
        >
          <div style={{ color: 'var(--on-surface-variant)' }}>For now, use the staff portal and onboarding docs to continue setup.</div>
          <div>Email: `spidercow711@gmail.com`</div>
          <div>Next step: create staff accounts, load roster data, and connect the member app to your live gym.</div>
        </section>
      </div>
    </main>
  );
}

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
