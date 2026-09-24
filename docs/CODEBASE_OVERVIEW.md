# Tether — Codebase Overview

> Last updated: September 2026. Source of truth for what exists in the repo today.

## Project Summary

Tether is a multi-tenant gym companion platform. Each gym is an isolated tenant. Members authenticate via roster-gated login, track workouts offline-first, share completed sessions to a gym-wide social feed, and (soon) receive real gym notices. Gym staff manage members and content via NestJS staff APIs today; a Next.js admin portal is planned but not built yet.

---

## Repository Structure

```
Gym-Companion/
├── Tether/                         # Flutter mobile app (iOS, Android, desktop)
├── gym-app-backend/                # NestJS REST API + Prisma + Supabase Auth
├── tether-web/                     # Next.js staff portal + marketing pages
└── docs/                           # Living docs for the monorepo
    └── archive/                    # Superseded plans, product notes, design guides
```

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Mobile | Flutter 3.x + Riverpod | Offline-first with Drift/SQLite |
| Backend API | NestJS 10.x | All business logic for app + future admin |
| ORM | Prisma 5.x | Against PostgreSQL |
| Database | PostgreSQL (Supabase-hosted) | Local Postgres used for some dev setups |
| Auth | Supabase Auth | JWT validated by NestJS; roster OTP + password flows |
| Storage | Supabase Storage | Post workout images, exercise media |
| RLS | Supabase RLS | Defense-in-depth; app still goes through NestJS |
| Admin portal | Next.js (planned) | Will call NestJS, not replace it |
| Brand accent | Neon lime `#C3F400` | Dark surfaces; not orange |

---

## Architecture

```
Flutter App (Tether/)
    │
    ├── Auth / workouts / social / members ──► NestJS (:3000)
    │                                              │
    ├── Supabase session (persist/refresh) ───────►│
    │                                              ▼
    └── Gym list (can use NestJS /gyms)      PostgreSQL via Prisma
                                             (+ Supabase Auth / Storage)

Future:
Next.js Admin ──JWT/cookie──► NestJS ──► same database
```

**Key decision:** Flutter talks to **NestJS for almost all business logic**. NestJS uses the Supabase **service role** (never exposed to clients) via Prisma / Supabase admin APIs. RLS exists so a future website or selective direct reads can be safe, but the mobile app is **not** Supabase-direct for social/workouts.

---

## Locked Product Decisions (v1)

These override older plan docs that mentioned follows, multi-gym, or Supabase-direct Flutter:

| Decision | Choice |
|---|---|
| Gym membership | **One gym per user** (`users.gym_id`) |
| Feed | **Gym-wide**, newest-first (no following system) |
| Workout share | Only after a completed session; optional single photo |
| Coach certification | One badge per post; any coach/staff in that gym |
| Routines | Private by default; optional gym share as snapshot |
| Access | Roster-gated (no open signup) |
| API layer | NestJS remains the source of business rules |
| Brand | Lime `#C3F400` on dark UI |

Deferred (not v1): multi-gym (`user_gyms`), following graph, web member feed, Stripe billing UI.

---

## Mobile App (`Tether/`)

### Feature status

| Area | Status |
|---|---|
| Auth (gym select, OTP, password, set password) | Working |
| Offline workouts (Drift + background sync) | Working |
| Train tab (builder, session, Hevy-style logging UI) | Working |
| Routines / templates / copy | Working |
| Exercise detail, progress, history | Working |
| Social feed (likes, comments, flag) | Working |
| Share workout to feed + pending share queue | Working (verify on device) |
| Coach certify post | Working |
| Member profiles (same-gym) | Working |
| Home screen layout | Working |
| Gym notices | **Wired to NestJS** (`GET /notices`); coach compose in app |
| Coach tips on Home | **Removed** (were hardcoded) |
| Push notifications | Token table exists; delivery not built |
| Realtime feed | Not built |

### Directory structure (high level)

```
Tether/lib/
├── main.dart
├── core/
│   ├── api_client.dart              # Dio → NestJS; JWT sync/refresh
│   ├── config/supabase_config.dart
│   ├── database/                    # Drift offline DB + DAOs
│   ├── sync/                        # SyncService, Workmanager, connectivity
│   ├── navigation/main_navigation.dart
│   ├── theme/app_theme.dart
│   └── widgets/                     # glass_card, cached_media, media_catalog
└── features/
    ├── auth/
    ├── home/
    ├── workouts/                    # screens, widgets (Hevy UI), offline service
    ├── social/                      # feed, share queue, post media
    ├── profile/                     # member profile + service
    ├── notices/                     # placeholder notices UI
    └── notifications/               # screen shell
```

### Navigation

```dart
NavTab.home    = 0  // HomeScreen
NavTab.train   = 1  // WorkoutsScreen
NavTab.feed    = 2  // SocialScreen
NavTab.profile = 3  // ProfileScreen
```

### Auth flow (current)

1. App restores Supabase session if present → `MainNavigation`
2. Else gym selection → roster check (`POST /auth/check-member`)
3. OTP and/or password login via NestJS (`/auth/request-otp`, `/auth/verify-otp`, `/auth/login`, `/auth/set-password`)
4. NestJS injects JWT metadata (`gym_id`, `member_id`, `role`) and returns tokens
5. Flutter stores session via `supabase.auth.setSession` and sends Bearer JWT on NestJS calls

---

## Backend (`gym-app-backend/`)

### Modules

| Module | Responsibility |
|---|---|
| `auth` | Member OTP/password, claim session, staff login/invite |
| `roster` | CSV import, pending entries, approve |
| `gyms` | Public gym list; staff stats + member list |
| `workouts` | Exercises, sessions, sets, routines, templates, progress, profile patch |
| `social` | Feed, staff posts, workout share, like/flag/comment, coach certify |
| `members` | Same-gym member profile |
| `prisma` / `supabase` | DB + Auth/Storage helpers |

### Important API surfaces

- `POST /auth/*` — member + staff auth
- `GET /gyms`, `GET /gyms/:id/stats`, `GET /gyms/:id/members` (staff)
- `GET|POST /roster/*` — roster management
- `GET/POST/PATCH/DELETE` workouts, routines, sessions, sets
- `GET /social/posts` — gym-wide feed
- `POST /social/workout-sessions/:sessionId/share`
- `POST /social/posts/:id/certify` (staff)
- `GET /members/:memberId/profile`

### Core tables (Prisma)

| Table | Purpose |
|---|---|
| `gyms` | Tenants (incl. `timezone`, branding fields) |
| `gym_roster` | Pre-approved members |
| `gym_staff` | Staff accounts for admin / `isStaff` |
| `users` | Members; **single** `gym_id` |
| `exercises` | Global + custom exercises |
| `workout_sessions` / `workout_sets` | Logged workouts |
| `workout_templates` (+ exercises) | Routines / programs |
| `saved_exercises` / `saved_programs` / `recently_used_exercises` | Personal library |
| `user_achievements` | PRs / milestones |
| `posts` | Feed entries; optional `workout_session_id`, image |
| `post_likes` / `post_comments` / `post_flags` | Engagement + moderation |
| `coach_certifications` | One certification per post |
| `push_tokens` | Device tokens (delivery TBD) |

**Not in schema (despite older plans):** `profiles`, `user_gyms`, `user_follows`, `gym_notices`, `reports`, `notifications`, `gym_analytics`.

### Supabase migrations (backend folder)

Notable recent migrations:

| File | Contents |
|---|---|
| `008_rls_policies.sql` | JWT helpers + gym-scoped RLS |
| `009_workout_media_certification.sql` | Post media + coach certification |
| `010_routine_session_link.sql` | Routine ↔ session link |
| `011_gym_timezone.sql` | Gym timezone |

---

## Design System (mobile)

- **Accent:** `#C3F400` (neon lime) — single brand color
- **Surfaces:** dark hierarchy from `#0D0E12` upward
- **Type:** Oswald (display), Inter (body), JetBrains Mono (labels)
- **Spacing:** 8px base unit

Website/admin should reuse this lime brand (older plan docs that used orange `#FF6B35` are obsolete).

---

## Current Status Snapshot

### Working
- Roster-gated auth + NestJS JWT guard
- Offline-first workout logging and sync
- Gym-wide social feed with share / like / comment / flag / certify
- Member profiles
- Staff API hooks (stats, members, staff posts, roster)
- RLS policies applied for future direct access

### Gaps before pilot
- Real notices backend + replace Home/Notices placeholders
- Replace hardcoded coach tips
- Device verification of feed auth + share queue
- Push notification delivery
- Next.js admin portal + marketing site (**not started**)

---

## Environment Variables

### Backend (`.env`)

```
DATABASE_URL=...
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...   # Never expose to clients
SUPABASE_JWT_SECRET=...
PORT=3000
```

### Flutter (`--dart-define` / config)

```
SUPABASE_URL=...
SUPABASE_PUBLISHABLE_KEY=...    # Safe for clients
API base URL configured in ApiClient (device LAN IP for physical devices)
```

---

## Development Commands

```bash
# Backend
cd gym-app-backend
npm run start:dev
npm run build
npx prisma generate
npx prisma migrate dev

# Flutter
cd Tether
flutter run
flutter analyze lib/
dart run build_runner build --delete-conflicting-outputs
```

---

## Related docs

| Doc | Role |
|---|---|
| `docs/WEBSITE_PLAN.md` | Admin + marketing website plan (NestJS-backed) |
| `docs/archive/tether-plan/` | Website phases, schema/API reference, developer guide |
| `docs/archive/product/` | Product decisions and rationale |
| `gym-app-backend/docs/` | Backend-focused architecture notes |
