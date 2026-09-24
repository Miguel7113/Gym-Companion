# TETHER — Website Build Plan
## Revised roadmap (aligned to existing Flutter + NestJS)

> **Status:** Website not started. Mobile app + NestJS backend are the source of truth.
> **Brand:** Neon lime `#C3F400` on dark surfaces (not orange).
> **Architecture:** Next.js admin/marketing site calls **NestJS**, same as the Flutter app. Do not rebuild a parallel Supabase-direct schema.

See also: `docs/CODEBASE_OVERVIEW.md`, `docs/WEBSITE_PLAN.md`.

---

## Overview

| Phase | Focus | Deliverable |
|-------|-------|-------------|
| A | App stabilization | Notices/tips real; feed share verified on device |
| B | Website foundation | `tether-web` scaffolded, design system, NestJS client |
| C | Staff auth + dashboard | Staff login, stats cards, gym context |
| D | Members & roster | Member table, CSV import, pending approvals |
| E | Notices & moderation | Notices CRUD (once model chosen), flagged-post queue |
| F | Marketing site | Landing, pricing, for-gyms, deploy |
| G | Post-pilot | Analytics charts, push from admin, realtime (optional) |

Older 8-week plans that started with marketing + greenfield Supabase tables are **obsolete**.

---

## Locked decisions (do not re-litigate in this plan)

| Topic | Decision |
|-------|----------|
| Data access | NestJS API for app and website |
| Membership | **Single gym per user** (`users.gym_id`) — multi-gym deferred |
| Feed | **Gym-wide**, newest-first — **no follows** |
| Notices | `gym_notices`; Home/Notices only; pin+tags; soft-delete; no images yet |
| Notice authors | Coaches in **app**; admins on **website** |
| Website | Admin portal first (`tether-web/` at repo root); marketing later; push after website |
| Next after notices | Device-verify feed/share |
| Roster | CSV + manual in admin MVP |
| Share | After completed workout; optional single image |
| Coach badge | One `coach_certifications` row per post |
| Brand | Lime `#C3F400` |

---

## PHASE A — App stabilization (before / alongside website)

- [ ] NestJS `gym_notices` schema (pin, tag, soft-delete; no images yet) + CRUD
- [ ] Coach can create notices in Flutter; members read on Home + Notices (not Feed)
- [ ] Wire Flutter Home + Notices screens (replace placeholders)
- [ ] Verify feed JWT refresh + workout share on a physical device
- [ ] Replace hardcoded Home coach tips if still placeholder (optional vs notices)

---

## PHASE B — Website foundation

```bash
npx create-next-app@latest tether-web --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm
cd tether-web
npx shadcn@latest init --yes --base-color zinc
# Install: tanstack query/table, react-hook-form, zod, recharts, lucide-react, sonner, etc.
```

**Tasks:**

- [ ] Place project at repo root: `tether-web/` next to `Tether/` and `gym-app-backend/`
- [ ] Design tokens matching Flutter: lime accent, dark surfaces
- [ ] `lib/api.ts` — typed NestJS client (Bearer JWT from staff session)
- [ ] Env: `NEXT_PUBLIC_API_URL`, Supabase URL/anon only if needed for staff session cookies
- [ ] Route groups: `(marketing)/`, `(auth)/`, `(dashboard)/`

**Do not:** invent `profiles` / `follows` / orange theme / direct Prisma from Next.js.

---

## PHASE C — Staff auth + dashboard

**Use existing backend:**

- `POST /auth/staff/login`
- `POST /auth/staff/invite`
- `GET /gyms/:id/stats`
- `GET /gyms/:id/members`

**Tasks:**

- [ ] Staff login page (email + password)
- [ ] Session storage (HTTP-only cookie or secure client storage holding NestJS/Supabase tokens)
- [ ] Dashboard layout: sidebar, gym name, sign out
- [ ] Overview page: member count, workouts this week, pending roster
- [ ] Auth guard on all `(dashboard)` routes

---

## PHASE D — Members & roster

**Use existing backend:**

- `GET /gyms/:id/members`
- `POST /roster/import-csv`
- `POST /roster/entry`
- `GET /roster/pending/:gymId`
- `POST /roster/approve/:rosterId`

**Tasks:**

- [ ] Members data table (search, role/staff indicator if available)
- [ ] CSV import with preview + error report
- [ ] Pending roster approval queue
- [ ] Link to member profile summary (read-only from NestJS where available)

---

## PHASE E — Notices & feed moderation

**Depends on Phase A notices decision.**

**Existing today:**

- `POST /social/posts` (staff announcements)
- `GET /social/posts` (gym feed)
- Flag fields on posts; flag endpoint from app

**Tasks:**

- [ ] Notices/announcements create + list + pin (if model supports)
- [ ] Moderation queue: flagged posts, soft-delete / dismiss
- [ ] Optional: coach certify from web (`POST /social/posts/:id/certify`)

---

## PHASE F — Marketing site

**Tasks:**

- [ ] Landing (brand-first lime dark composition)
- [ ] Pricing / for-gyms / contact or demo request
- [ ] Footer + nav linking to staff login
- [ ] Deploy (e.g. Vercel); API URL points at hosted NestJS

---

## PHASE G — Post-pilot (optional)

- Analytics charts backed by NestJS aggregation endpoints (not a separate `gym_analytics` table unless needed)
- Realtime feed updates (Supabase Realtime or NestJS SSE) — only if polling is painful
- Stripe billing UI
- Multi-gym staff switcher — **only after** multi-gym exists in schema (deferred)

---

## Suggested week sketch (flexible)

| Week | Work |
|------|------|
| 1 | Phase A notices + device verify share |
| 2 | Phase B scaffold + design system + API client |
| 3 | Phase C auth + dashboard |
| 4 | Phase D members + roster |
| 5 | Phase E notices UI + moderation |
| 6 | Phase F marketing + deploy |

---

## Explicit non-goals

- Greenfield schema from the old `profiles` / `follows` / `gym_members` plan
- Flutter talking to Supabase for workouts/social instead of NestJS
- Following system
- Member web social feed in v1
- Orange `#FF6B35` branding
