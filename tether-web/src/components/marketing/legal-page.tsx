import type { ReactNode } from 'react';

export function LegalPage({ title, updated, children }: { title: string; updated: string; children: ReactNode }) {
  return (
    <>
      <section className="mk-dark" style={{ padding: 'clamp(150px, 16vw, 200px) 0 clamp(56px, 7vw, 88px)' }}>
        <div className="mk-container">
          <span className="mk-eyebrow">Legal</span>
          <h1 className="mk-h2" style={{ marginTop: 24 }}>
            {title}
          </h1>
          <p className="mk-lead" style={{ marginTop: 20 }}>
            Last updated {updated}
          </p>
        </div>
      </section>
      <section className="mk-section mk-white-bg" style={{ paddingTop: 'clamp(56px, 7vw, 88px)' }}>
        <div className="mk-container">
          <div className="mk-prose">
            <p className="mk-draft-note">
              This is a working draft while Tether is in its pilot phase. It will be reviewed before wider launch.
            </p>
            {children}
          </div>
        </div>
      </section>
    </>
  );
}
