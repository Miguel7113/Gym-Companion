import Link from 'next/link';
import { loginStaff } from './actions';

export default async function LoginPage({
  searchParams,
}: {
  searchParams?: Promise<{ error?: string }>;
}) {
  const params = (await searchParams) ?? {};

  return (
    <main
      className="page-shell"
      style={{ display: 'grid', placeItems: 'center', padding: 24 }}
    >
      <div className="panel" style={{ width: '100%', maxWidth: 440 }}>
        <div style={{ marginBottom: 24 }}>
          <p className="page-kicker">Tether Admin</p>
          <h1 className="page-title" style={{ fontSize: 32 }}>
            Staff login
          </h1>
          <p className="page-subtitle">
            Sign in to manage roster, notices, members, and feed moderation.
          </p>
        </div>

        <form action={loginStaff} className="stack">
          {params.error ? (
            <div className="alert alert-error">{params.error}</div>
          ) : null}

          <label className="stack" style={{ gap: 8 }}>
            <span className="muted" style={{ fontSize: 14 }}>
              Email
            </span>
            <input
              type="email"
              name="email"
              placeholder="staff@yourgym.com"
              className="field"
              required
            />
          </label>

          <label className="stack" style={{ gap: 8 }}>
            <span className="muted" style={{ fontSize: 14 }}>
              Password
            </span>
            <input
              type="password"
              name="password"
              placeholder="Enter password"
              className="field"
              required
            />
          </label>

          <button type="submit" className="btn btn-primary">
            Sign in
          </button>

          <Link href="/" className="btn btn-ghost" style={{ justifyContent: 'center' }}>
            ← Back to site
          </Link>
        </form>
      </div>
    </main>
  );
}
