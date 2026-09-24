# TETHER — Website Developer Guide
## Next.js admin + marketing on top of NestJS

> Version 2.0 — rewritten September 2026.
> Old guide assumed Next.js → Supabase direct as the only backend. That is **wrong for this repo**.

Companion docs:

- `TETHER_Build_Plan.md` — phases
- `TETHER_Database_and_API.md` — real tables + NestJS routes
- `docs/WEBSITE_PLAN.md` — portal feature scope
- `docs/CODEBASE_OVERVIEW.md` — monorepo status

---

## 1. Tech stack (website)

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Next.js 15 App Router | Marketing SSR + dashboard |
| Language | TypeScript | Match NestJS |
| Styling | Tailwind + shadcn/ui | Dark zinc base |
| Brand | Lime `#C3F400` | Match Flutter `AppTheme.primaryContainer` |
| Server state | TanStack Query | All NestJS fetches |
| Tables | TanStack Table | Members / roster |
| Forms | React Hook Form + Zod | Admin forms |
| Charts | Recharts | Post-MVP analytics |
| Backend | **Existing NestJS** | Do not duplicate business rules |

Optional: `@supabase/ssr` only if you store staff Supabase sessions in cookies. Authorization for gym data still goes through NestJS (`StaffAuthGuard` / staff checks).

---

## 2. System diagram

```
Browser (tether-web)
  │
  ├─ Marketing pages (public)
  └─ Dashboard pages
        │  Authorization: Bearer <access_token>
        ▼
   gym-app-backend (NestJS)
        │
        ▼
   PostgreSQL + Supabase Auth/Storage
```

Flutter already uses this path. The website is a second client.

---

## 3. Project init

```bash
# From Gym-Companion repo root
npx create-next-app@latest tether-web --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm
cd tether-web
npx shadcn@latest init --yes --base-color zinc
```

Suggested deps: `@tanstack/react-query`, `@tanstack/react-table`, `react-hook-form`, `@hookform/resolvers`, `zod`, `lucide-react`, `sonner`, `date-fns`, `recharts`, `clsx`, `tailwind-merge`.

Env (`.env.local`):

```
NEXT_PUBLIC_API_URL=http://localhost:3000
# Optional Supabase client keys if using SSR session helpers
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

---

## 4. Design tokens

Match Flutter — **not** the old orange plan:

```ts
// src/lib/design-tokens.ts
export const brand = {
  lime: '#C3F400',
  limePressed: '#ABD600',
  onLime: '#161E00',
  surface: '#121317',
  surfaceLow: '#1A1B1F',
  surfaceHigh: '#292A2E',
  onSurface: '#E3E2E7',
  outline: '#8E9379',
} as const;
```

Fonts: prefer expressive display + clean body (avoid default Inter-only marketing if building landing; dashboard can stay utilitarian). Keep lime as the single accent.

---

## 5. NestJS API client pattern

```ts
// src/lib/api.ts
export async function apiFetch<T>(
  path: string,
  options: RequestInit & { token?: string } = {},
): Promise<T> {
  const { token, headers, ...rest } = options;
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}${path}`, {
    ...rest,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`${res.status} ${path}: ${body}`);
  }
  return res.json() as Promise<T>;
}
```

Examples:

- Stats: `GET /gyms/:gymId/stats`
- Members: `GET /gyms/:gymId/members`
- Staff login: `POST /auth/staff/login`
- Announce: `POST /social/posts` with staff token
- Certify: `POST /social/posts/:id/certify`

Full route list: `TETHER_Database_and_API.md`.

---

## 6. Suggested file structure

```
tether-web/src/
├── app/
│   ├── (marketing)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── pricing/page.tsx
│   │   └── for-gyms/page.tsx
│   ├── (auth)/
│   │   └── login/page.tsx
│   └── (dashboard)/
│       ├── layout.tsx          # sidebar + require staff session
│       ├── page.tsx            # overview stats
│       ├── members/page.tsx
│       ├── roster/page.tsx
│       ├── notices/page.tsx    # after notices API exists
│       ├── feed/page.tsx       # moderation
│       └── settings/page.tsx
├── components/
│   ├── ui/                     # shadcn
│   ├── layout/
│   └── dashboard/
├── lib/
│   ├── api.ts
│   ├── auth.ts
│   ├── design-tokens.ts
│   └── utils.ts
└── types/
    └── api.ts                  # mirror NestJS DTOs as needed
```

---

## 7. Auth pattern (staff)

1. Login form → `POST /auth/staff/login` with email/password.
2. Store returned access/refresh tokens securely (httpOnly cookie preferred).
3. Dashboard layout reads session; if missing → `/login`.
4. Every NestJS call sends `Authorization: Bearer …`.
5. On 401: refresh once, then force re-login.

Never treat “any Supabase user” as staff. NestJS must confirm `gym_staff`.

---

## 8. Dashboard MVP checklist

1. Staff login
2. Overview stats (existing `/gyms/:id/stats`)
3. Members table (`/gyms/:id/members`)
4. Roster CSV + pending approve (existing roster routes)
5. Announcements / notices (after Flutter notices decision)
6. Flagged post moderation (extend social APIs if list-flagged endpoint missing)

---

## 9. Marketing pages checklist

- Brand-first hero (lime + dark; product name dominant)
- One CTA to book demo / contact + link to staff login
- Pricing / for-gyms as separate sections or routes
- No fake “live dashboard” cards in the first viewport

---

## 10. What not to implement from old guides

| Old guide idea | Status |
|----------------|--------|
| `profiles` + `follows` schema | Rejected for v1 |
| Direct Supabase CRUD for feed | Rejected — use NestJS |
| Orange `#FF6B35` theme | Rejected — use lime |
| Multi-gym switcher | Deferred until schema supports it |
| Edge Function as only roster importer | NestJS roster routes already exist |
| Website week 1 before app | Obsolete — app exists |

---

## 11. Testing & deploy (later)

- Unit-test API client error handling
- Playwright smoke: login → dashboard stats
- Deploy Next.js to Vercel/host; point `NEXT_PUBLIC_API_URL` at production NestJS
- CORS: allow the web origin on NestJS

---

## 12. Implementation order

Follow `TETHER_Build_Plan.md` phases B→F. Do not start marketing polish before staff login + stats work against the real API.
