# Tether — Admin Portal & Website Plan

> Updated September 2026 to match the **existing NestJS + Prisma** backend.
> Older drafts that said “Next.js talks only to Supabase / no NestJS” are obsolete.

## Overview

The website has two surfaces in one Next.js app (recommended layout):

1. **Marketing** — landing, pricing, for-gyms (public, SEO)
2. **Admin portal** — gym staff dashboard (auth required)

Both share the same dark + lime brand as the Flutter app (`#C3F400`). The portal does **not** replace NestJS. It is another client of `gym-app-backend`, same as Flutter.

```
Flutter App ──JWT──► NestJS ◄──JWT/session── Next.js (admin)
                        │
                        ▼
                 PostgreSQL (Supabase)
                 + Supabase Auth / Storage
```

RLS remains useful as defense-in-depth if the website ever reads selected tables directly. Day-one rule: **business logic stays in NestJS**.

---

## Tech Stack

| Component | Technology | Rationale |
|---|---|---|
| Framework | Next.js 15 (App Router) | SSR for auth routes + marketing SEO |
| Language | TypeScript | Aligns with NestJS |
| Styling | Tailwind CSS + shadcn/ui | Fast dashboard UI |
| Tables / charts | TanStack Table, Recharts | Members + analytics |
| Forms | React Hook Form + Zod | Validated admin forms |
| Server state | TanStack Query | Call NestJS APIs |
| Auth | Supabase Auth for staff session **plus** NestJS `POST /auth/staff/login` | Staff must exist in `gym_staff` |
| Brand | Lime `#C3F400`, dark surfaces | Match Flutter `AppTheme` |

---

## Project Structure (planned)

```
tether-web/   # not created yet — add at repo root
├── src/
│   ├── app/
│   │   ├── (marketing)/          # public pages
│   │   │   ├── page.tsx          # landing
│   │   │   ├── pricing/
│   │   │   └── for-gyms/
│   │   ├── (auth)/
│   │   │   └── login/page.tsx    # staff login
│   │   └── (dashboard)/
│   │       ├── layout.tsx        # sidebar + auth gate
│   │       ├── page.tsx          # stats overview
│   │       ├── members/
│   │       ├── notices/          # needs notices API first
│   │       ├── feed/             # moderate + announce
│   │       ├── roster/
│   │       └── settings/
│   ├── components/
│   ├── lib/
│   │   ├── api.ts                # NestJS fetch client
│   │   ├── auth.ts
│   │   └── design-tokens.ts      # lime brand tokens
│   └── types/
└── ...
```

---

## Auth — Staff vs Members

| | Members (Flutter) | Staff (Admin portal) |
|---|---|---|
| Login | Roster check + OTP / password via NestJS | Email + password via NestJS `POST /auth/staff/login` |
| Identity table | `users` + `gym_roster` | `gym_staff` |
| Session | Supabase session in app | Cookie / stored JWT for Next.js calling NestJS |
| Authorization | `SupabaseAuthGuard` + gym membership | `StaffAuthGuard` / `isStaff` on NestJS |

Do **not** assume any Supabase user can open the dashboard. Always verify `gym_staff`.

Existing backend hooks already useful for the portal MVP:

- `POST /auth/staff/login`, `POST /auth/staff/invite`
- `GET /gyms/:id/stats`
- `GET /gyms/:id/members`
- Roster CSV import / approve routes
- Staff-only `POST /social/posts`
- Flagged posts via social APIs (extend moderation views as needed)

---

## Feature Plan (portal MVP)

### Must-have for first gym pilot

1. Staff login
2. Dashboard stats (member count, workouts this week, pending roster)
3. Members list + search
4. Roster CSV import / pending approval
5. Create announcements (once notices API exists — see below)
6. Feed moderation (flagged posts, hide/delete, optional certify)

### Nice-to-have soon after

- Gym settings (name, logo, primary color, timezone)
- Basic analytics charts
- Template/routine library management

### Marketing site (can follow portal)

- Landing, pricing, for-gyms, contact/demo
- Brand-first lime dark theme; link to staff login

---

## Notices dependency (decided)

- Dedicated **`gym_notices`** table + NestJS CRUD; **soft-delete**
- Shown on **Home + Notices** only — **not** in the social feed
- v1: **pins + tags**; images later
- **Coaches create notices in the Flutter app**; **admins manage gym on the website** (roster CSV + manual, notices, stats, moderation)
- Feed stays **gym-wide** (no following); **multi-gym deferred**
- After notices: **device-verify feed/share**, then scaffold **`tether-web/`**, then marketing, then push

---

## Implementation phases (revised order)

Older plans started with marketing week 1. Actual order:

| Phase | Focus | Depends on |
|---|---|---|
| A | Stabilize Flutter (feed share, notices, tips) | NestJS notices decision |
| B | Scaffold `tether-web` + staff auth + dashboard stats | Existing gyms staff APIs |
| C | Members + roster management UI | Existing roster APIs |
| D | Notices + feed moderation UI | Notices model + social flags |
| E | Marketing pages + deploy | Brand tokens locked |
| F | Analytics, realtime, billing | Post-pilot |

---

## Explicit non-goals for website v1

- Replacing NestJS with Supabase-direct CRUD for workouts/social
- Member-facing web feed (mobile-first)
- Multi-gym staff switcher until multi-gym exists in schema
- Following / social graph features
- Orange accent / unrelated design system

---

## Related docs

- `docs/CODEBASE_OVERVIEW.md` — current app/backend status
- `docs/EXECUTION_PLAN.md` — **ticketed build order (start here for implementation)**
- `docs/archive/tether-plan/TETHER_Build_Plan.md` — week-by-week website build
- `docs/archive/tether-plan/TETHER_Database_and_API.md` — **actual** schema + NestJS API map
- `docs/archive/tether-plan/TETHER_Developer_Guide.md` — Next.js implementation notes
