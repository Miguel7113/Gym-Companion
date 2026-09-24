# TETHER — Database & API (Actual)
## Source of truth: Prisma + NestJS

> Replaces the old greenfield plan (`profiles`, `follows`, `gym_members`, orange branding).
> Canonical schema: `gym-app-backend/prisma/schema.prisma`
> Canonical API: `gym-app-backend/src/**/*.controller.ts`

---

## 1. Architecture

```
Clients (Flutter, future Next.js)
        │  Bearer JWT (Supabase Auth)
        ▼
   NestJS (Prisma + service role)
        ▼
   PostgreSQL (Supabase)
```

- **Do not** treat Supabase client + RLS as the primary API for workouts/social.
- RLS (`008_rls_policies.sql`) is defense-in-depth for optional direct reads later.
- JWT helpers expect metadata: `gym_id`, `member_id`, `role`.

---

## 2. Locked domain rules

| Rule | Implementation |
|------|----------------|
| One gym per member | `users.gym_id` (no `user_gyms`) |
| Gym-wide feed | `posts` filtered by `gym_id`, newest first |
| No follows | No `user_follows` / `follows` table |
| Workout share | `posts.workout_session_id` unique optional FK |
| One image per post | `image_url` / `image_path` |
| Coach certify | `coach_certifications` 1:1 with `posts` |
| Staff | `gym_staff` separate from `users` |
| Roster gate | `gym_roster` before / during signup |

---

## 3. Core tables (summary)

### Tenancy & people

| Table | Purpose |
|-------|---------|
| `gyms` | Tenant; branding; `timezone`; subscription fields |
| `gym_roster` | Pre-approved emails/phones; `unmatched` / `matched` / `pending` |
| `gym_staff` | Admin portal accounts; `auth_provider_id` |
| `users` | Members after claim; **single** `gym_id`; profile fields |

### Workouts

| Table | Purpose |
|-------|---------|
| `exercises` | Global library + custom (`is_custom`) |
| `workout_sessions` | Logged workouts; soft delete via `deleted_at` |
| `workout_sets` | Strength + cardio fields; soft delete |
| `workout_templates` + `workout_template_exercises` | Routines / programs |
| `saved_exercises` / `saved_programs` / `recently_used_exercises` | Personal library |
| `user_achievements` | PRs / milestones (can spawn posts) |

### Social

| Table | Purpose |
|-------|---------|
| `posts` | Feed rows; optional workout link + image + achievement |
| `post_likes` | Unique `(post_id, user_id)` |
| `post_comments` | Soft-deletable comments |
| `post_flags` | Moderation signals |
| `coach_certifications` | One coach badge per post |

### Infra

| Table | Purpose |
|-------|---------|
| `user_sessions` | Refresh token tracking |
| `push_tokens` | Device tokens (delivery TBD) |

### Not present (older plans — do not add unless product decides)

- `profiles` (use `users`)
- `user_gyms` / multi-gym junction
- `user_follows` / `follows`
- `reports`, `notifications`, `gym_analytics` as dedicated tables

**In progress / shipping:** `gym_notices` (Stage 1) — see NestJS `NoticesModule`.

---

## 4. Key models (field-level)

### `gyms`
`id`, `name`, `logo_url`, `primary_color`, `timezone` (default `UTC`), `contact_email`, `subscription_tier`, `is_active`, timestamps.

### `users`
`id`, `gym_id`, `roster_id?`, `email?`, `phone?`, `display_name?`, `gender?`, `body_weight_kg?`, `height_cm?`, `subscription_tier`, `auth_provider_id?` (unique), timestamps.

### `posts`
`id`, `gym_id`, `user_id`, `workout_session_id?` (unique), `content?`, `image_url?`, `image_path?`, `achievement_type?`, `achievement_id?`, `is_flagged`, `is_deleted`, timestamps.

There is **no** `post_type` enum today. Infer type in clients:

- Has `workout_session_id` → workout share
- Staff-created via `POST /social/posts` → announcement / tip
- Has `achievement_*` → achievement post

### `coach_certifications`
`id`, `post_id` (unique), `coach_user_id`, `gym_id`, `created_at`.

---

## 5. NestJS API map

Base URL: NestJS (`:3000` in local dev). All protected routes: `Authorization: Bearer <supabase_access_token>` unless `@Public()`.

### Auth (`/auth`)

| Method | Path | Notes |
|--------|------|-------|
| POST | `/auth/check-member` | Roster check before login |
| POST | `/auth/request-otp` | OTP send |
| POST | `/auth/verify-otp` | OTP verify + user claim |
| POST | `/auth/login` | Password login |
| POST | `/auth/set-password` | After OTP / first login |
| POST | `/auth/forgot-password` | Reset flow |
| POST | `/auth/claim-session` | Attach session |
| POST | `/auth/staff/login` | Admin portal |
| POST | `/auth/staff/invite` | Invite staff |

### Gyms (`/gyms`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/gyms` | Public active gyms |
| GET | `/gyms/:id` | Gym detail |
| GET | `/gyms/:id/stats` | Staff — members / workouts / pending |
| GET | `/gyms/:id/members` | Staff — member list |

### Roster (`/roster`)

| Method | Path | Notes |
|--------|------|-------|
| POST | `/roster/import-csv` | Bulk import |
| POST | `/roster/entry` | Single entry |
| GET | `/roster/pending/:gymId` | Pending queue |
| POST | `/roster/approve/:rosterId` | Approve |

### Workouts (selected)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/exercises`, `/exercises/:id`, filters | Library |
| CRUD | `/workouts/sessions`, sets | Logging |
| CRUD | `/workouts/routines` | Member routines |
| POST | `/workouts/routines/:id/copy` | Snapshot copy |
| GET | `/workouts/routines/:id/leaderboard` | Certified-aware |
| GET | `/workouts/progress/:exerciseId` | Progress |
| PATCH | `/users/me/profile` | Profile fields |

### Social (`/social`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/social/posts` | Gym-wide feed (`limit`/`offset`) |
| POST | `/social/posts` | **Staff only** announcements |
| POST | `/social/workout-sessions/:sessionId/share` | Member share |
| POST | `/social/posts/:id/certify` | Staff certify |
| POST | `/social/posts/:id/like` | Toggle like |
| POST | `/social/posts/:id/flag` | Flag |
| GET/POST | `/social/posts/:id/comments` | Comments |
| DELETE | `/social/posts/:postId/comments/:commentId` | Delete own/staff |

### Members (`/members`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/members/:memberId/profile` | Same-gym profile |

---

## 6. Notices (Stage 1 — NestJS implemented)

Table **`gym_notices`** + NestJS `NoticesModule`. Surfaces: Home + Notices only (not feed). Soft-delete via `deleted_at`.

| Method | Path | Auth |
|--------|------|------|
| GET | `/notices` | Member |
| GET | `/notices/:id` | Member |
| POST / PATCH / DELETE | `/notices`… | Coach (`isStaff`) |
| POST | `/notices/:id/restore` | Coach |
| GET / POST / PATCH / DELETE | `/staff/notices`… | StaffAuthGuard (admin portal) |
| POST | `/staff/notices/:id/restore` | Staff |

Tags v1: `ANNOUNCEMENT` \| `CLASS_UPDATE` \| `REMINDER` \| `EVENT`. Pin supported; images later.

Migrations:
- `prisma/migrations/20260904120000_gym_notices/`
- `supabase/migrations/012_gym_notices.sql`

---

## 7. Storage

- Post images: paths stored on `posts.image_path` / `image_url` (see migration `009_workout_media_certification.sql`).
- Exercise GIFs / images: fields on `exercises`.
- Buckets configured in Supabase migrations (`006_storage_buckets.sql` and follow-ups).

---

## 8. Website implications

When building `tether-web`:

1. Call the NestJS routes above — do not invent parallel tables.
2. Staff auth via `/auth/staff/*`.
3. Dashboard MVP: stats, members, roster, then notices/moderation.
4. If you need a new admin capability, **add a NestJS endpoint first**, then the UI.

---

## 9. Migration index (Supabase SQL folder)

| Migration | Topic |
|-----------|--------|
| early `001–007` | Core schema, workouts, social, food drop |
| `008_rls_policies.sql` | JWT helpers + RLS |
| `009_workout_media_certification.sql` | Media + certification |
| `010_routine_session_link.sql` | Routine ↔ session |
| `011_gym_timezone.sql` | Gym timezone |

Always keep Prisma schema and SQL migrations in sync when changing production.
