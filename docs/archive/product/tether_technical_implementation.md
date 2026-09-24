# TETHER — Technical Implementation Notes
## NestJS + Flutter + planned Next.js

> Updated September 2026. This file no longer prescribes Flutter→Supabase-direct social or a `user_gyms` / follows migration as the default path.

For the live schema and route list, prefer:

- `gym-app-backend/prisma/schema.prisma`
- `docs/archive/tether-plan/TETHER_Database_and_API.md`

---

## 1. Target architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter app    │────►│  NestJS API      │────►│  PostgreSQL     │
│  (Tether/)      │ JWT │  (Prisma)        │     │  on Supabase    │
└─────────────────┘     │                  │     └─────────────────┘
                        │  + Supabase Admin│              ▲
┌─────────────────┐     │    (Auth/Storage)│              │
│  tether-web     │────►│                  │──────────────┘
│  (planned)      │     └──────────────────┘
└─────────────────┘
```

RLS policies exist under `gym-app-backend/supabase/migrations/008_rls_policies.sql`. They are **not** a license to move business logic out of NestJS.

---

## 2. Auth (as implemented)

### Member

1. `POST /auth/check-member` — roster gate
2. `POST /auth/request-otp` / `verify-otp` and/or `login` / `set-password`
3. NestJS creates/links `users`, sets Auth metadata (`gym_id`, `member_id`, `role`)
4. Flutter persists Supabase session; `ApiClient` refreshes on 401 and retries

### Staff

1. Rows in `gym_staff`
2. `POST /auth/staff/login` (+ invite)
3. Staff-only NestJS routes (`StaffAuthGuard` / `isStaff` checks)

---

## 3. Social (as implemented)

| Concern | Implementation |
|---------|----------------|
| Feed | `GET /social/posts?limit&offset` scoped by JWT `gymId` |
| Share | `POST /social/workout-sessions/:sessionId/share` |
| Staff post | `POST /social/posts` (forbidden for non-staff) |
| Like / flag / comments | Nested `/social/posts/:id/...` routes |
| Certify | `POST /social/posts/:id/certify` → `coach_certifications` |
| Offline share | Flutter `pending_workout_share_queue` + sync after reconnect |

**Do not add** `user_follows` unless product reopens that decision.

### Feed query shape (conceptual)

```sql
-- NestJS/Prisma equivalent
SELECT * FROM posts
WHERE gym_id = :gymId AND is_deleted = false
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```

---

## 4. Workouts (as implemented)

- Sessions/sets CRUD via NestJS
- Offline write path: Drift DAOs → `SyncService` / Workmanager
- Routines: `workout_templates` with gym share + copy-as-snapshot
- Leaderboards can prefer coach-certified sessions where applicable
- Hevy-style UI lives in Flutter widgets under `features/workouts/widgets/`

---

## 5. Notices (not implemented — choose before coding)

### Option A — Staff posts as notices (faster)

- Reuse `POST /social/posts`
- Add optional `achievement_type` or a new `post_kind` column later (`announcement`, `coach_tip`, …)
- Home queries latest staff posts / filtered kinds

### Option B — Dedicated table

```sql
-- Sketch only — not applied
CREATE TABLE gym_notices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id),
  author_user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  tag TEXT,              -- ANNOUNCEMENT | CLASS UPDATE | ...
  image_url TEXT,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Then NestJS CRUD + Flutter Home/Notices wiring + admin UI.

**Recommendation:** Option A for pilot speed unless notices must never appear in Feed.

---

## 6. Multi-gym / following (deferred)

Older drafts included:

- `user_gyms (user_id, gym_id, role, is_active)`
- `user_follows` gym-scoped

**Status:** Deferred. Do not migrate production to these for v1. Document again if a paying gym requires them.

---

## 7. Website technical notes

1. Create `tether-web` at repo root.
2. Typed fetch client → `NEXT_PUBLIC_API_URL`.
3. Staff session → call existing gyms/roster/social staff endpoints.
4. If a UI needs data NestJS cannot return, **extend NestJS first**.
5. CORS allow the web origin.

See `docs/archive/tether-plan/TETHER_Developer_Guide.md` for structure and tokens.

---

## 8. RLS helpers (already in SQL)

```sql
-- From migration 008 (conceptual)
public.get_my_gym_id()
public.get_my_member_id()
public.get_my_role()
public.is_staff()
```

These read JWT `user_metadata`. Keep NestJS claim injection consistent when changing auth.

---

## 9. Storage

- Workout post images: storage path on `posts.image_path` (+ public/signed `image_url` as needed)
- Exercise media: `exercises.gif_url` / `image_urls`
- Follow bucket policies in supabase migrations; uploads should go through controlled client flows (Flutter today, NestJS-signed URLs if required later)

---

## 10. Suggested engineering order

1. Notices decision + NestJS + Flutter wire-up
2. Harden share/feed auth on device
3. Scaffold `tether-web` + staff login + stats
4. Members + roster UI
5. Moderation + notices admin
6. Marketing pages + deploy

---

## 11. What to delete from muscle memory

| Old sample / idea | Replace with |
|-------------------|--------------|
| Flutter `supabase.from('posts')` for feed | `SocialService` → NestJS |
| `user_gyms` required for isolation | `users.gym_id` + NestJS where clause |
| Follow-based feed SQL | Gym-wide chronological feed |
| Orange design tokens | Lime `#C3F400` |
| Edge-only CSV | NestJS `/roster/import-csv` (extend if needed) |
