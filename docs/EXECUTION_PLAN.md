# Tether — Execution Plan (v1)
## Locked decisions → build order

> Written September 2026 after product lock-in.
> Source of truth for what to build next. Architecture: Flutter + NestJS; website = NestJS client.

---

## Locked decisions (do not re-open mid-build)

| Topic | Choice |
|-------|--------|
| Multi-gym | **Deferred** — `users.gym_id` only |
| Feed | **Gym-wide** — no follows |
| Notices | **`gym_notices`** — Home + Notices only, **not** Feed |
| Notice authors | **Coaches in Flutter**; **admins on website** |
| Notice fields | Title, body, **tag**, **pin**, soft-delete; **no images yet** |
| Website | Staff/admin only; folder **`tether-web/`** at repo root |
| Order | Notices → device-verify share → admin → marketing → push |
| Roster | CSV + manual in admin MVP |
| Brand | Lime `#C3F400` |

---

## Stage 0 — Preconditions (half day)

| ID | Task | Done when |
|----|------|-----------|
| 0.1 | Backend runs locally; Flutter hits correct `ApiClient` base URL for your device | Login works on device/emulator |
| 0.2 | Confirm `SUPABASE_JWT_SECRET` + service role in backend `.env` | Protected routes accept app JWT |
| 0.3 | Pick one test gym + coach user + admin/`gym_staff` row | Can exercise coach vs admin paths |

---

## Stage 1 — Gym notices (backend) ✅ code landed

**Goal:** Real notices API; soft-delete; coach + admin can write; members read.

| ID | Task | Notes |
|----|------|-------|
| 1.1 | Prisma model `GymNotice` → table `gym_notices` | Done |
| 1.2 | Prisma migrate + matching Supabase SQL migration | Files added — **apply to your DB** |
| 1.3 | NestJS `NoticesModule` (controller + service + DTOs) | Done |
| 1.4 | `GET /notices` (member) | Done |
| 1.5 | `GET /notices/:id` (member) | Done |
| 1.6 | `POST /notices` | Coach (`isStaff`) |
| 1.7 | `PATCH /notices/:id` | Done |
| 1.8 | Soft-delete `DELETE /notices/:id` | Done |
| 1.9 | Restore `POST /notices/:id/restore` + `/staff/notices` | Done |
| 1.10 | Unit/service tests | `notices.service.spec.ts` — 9 passing |

**Apply DB:** `npx prisma migrate deploy` (or `migrate dev`) and run `supabase/migrations/012_gym_notices.sql` on Supabase if that is production.

### Suggested schema

```text
gym_notices
  id                UUID PK
  gym_id            UUID NOT NULL → gyms
  author_user_id    UUID? → users     -- coach from app
  author_staff_id   UUID? → gym_staff -- admin from web (nullable until portal)
  title             TEXT NOT NULL
  body              TEXT NOT NULL
  tag               TEXT NOT NULL      -- ANNOUNCEMENT | CLASS_UPDATE | REMINDER | EVENT (or free string with allowlist)
  is_pinned         BOOLEAN NOT NULL DEFAULT false
  published_at      TIMESTAMPTZ NOT NULL DEFAULT now()
  created_at        TIMESTAMPTZ
  updated_at        TIMESTAMPTZ
  deleted_at        TIMESTAMPTZ?
```

Indexes: `(gym_id, deleted_at, is_pinned, published_at DESC)`.

---

## Stage 2 — Gym notices (Flutter) ✅ code landed

**Goal:** Kill placeholders; coaches can compose; members see real data.

| ID | Task | Notes |
|----|------|-------|
| 2.1 | `GymNotice` model + `NoticesService` | Done |
| 2.2 | `noticesProvider` | Done |
| 2.3 | `NoticesScreen` wired to API | Done |
| 2.4 | Home notices strip live | Done (no images v1) |
| 2.5 | Coach compose (`CreateNoticeSheet`) | FAB when JWT role coach/admin |
| 2.6 | Soft-delete from notice detail | Done |
| 2.7 | Removed hardcoded Home trainer tips | Done |

**Requires:** Stage 1 migration applied (`gym_notices` table).

**Out of scope here:** images on notices; posting notices into Feed.

---

## Stage 3 — Device-verify feed & workout share

**Goal:** Confirm recent auth/sync fixes on a **physical device**.

| ID | Task | Done when |
|----|------|-----------|
| 3.1 | Login on device with correct LAN API URL | No bogus host |
| 3.2 | Open Feed — loads without sticky 401 | |
| 3.3 | Complete workout → share (with/without photo) | Post appears in feed |
| 3.4 | Airplane mode → finish → reconnect | Pending share queue drains |
| 3.5 | Like / comment / flag / coach certify smoke | |
| 3.6 | Fix any regressions found | Before starting website |

---

## Stage 4 — Admin portal foundation (`tether-web/`)

**Goal:** Next.js app at repo root; staff login; shell + stats.

| ID | Task | Notes |
|----|------|-------|
| 4.1 | `create-next-app` → **`tether-web/`** | Tailwind, App Router, TS |
| 4.2 | Design tokens (lime `#C3F400`, dark surfaces) | Match Flutter |
| 4.3 | `lib/api.ts` NestJS client + env `NEXT_PUBLIC_API_URL` | |
| 4.4 | Staff login → `POST /auth/staff/login` | Persist token securely |
| 4.5 | `(dashboard)` layout: sidebar, auth gate, sign out | |
| 4.6 | Overview page → `GET /gyms/:id/stats` | Members / workouts week / pending |
| 4.7 | CORS on NestJS for web origin | |

---

## Stage 5 — Admin: roster + members

| ID | Task | Notes |
|----|------|-------|
| 5.1 | Members table → `GET /gyms/:id/members` | Search |
| 5.2 | Manual roster add → `POST /roster/entry` | |
| 5.3 | CSV import → `POST /roster/import-csv` | Preview + errors |
| 5.4 | Pending queue → list + `POST /roster/approve/:id` | |

---

## Stage 6 — Admin: notices + moderation

| ID | Task | Notes |
|----|------|-------|
| 6.1 | Notices list/create/edit/pin/soft-delete | Same NestJS notices API |
| 6.2 | Optional restore deleted | |
| 6.3 | Feed moderation view | Flagged posts; hide/dismiss; certify if useful |
| 6.4 | Extend NestJS if “list flagged” endpoint missing | Add before inventing client-only hacks |

---

## Stage 7 — Marketing site

| ID | Task | Notes |
|----|------|-------|
| 7.1 | `(marketing)` landing — brand-first lime/dark | |
| 7.2 | Pricing / for-gyms / contact or demo | |
| 7.3 | Nav link to staff login | |
| 7.4 | Deploy web; point API URL at hosted NestJS | |

---

## Stage 8 — Push (after website)

| ID | Task | Notes |
|----|------|-------|
| 8.1 | Register/refresh `push_tokens` from Flutter | |
| 8.2 | On notice create → notify gym members | NestJS or worker |
| 8.3 | Optional: like/comment/certify pushes later | |

---

## Explicit non-goals (v1)

- Multi-gym / `user_gyms`
- Following graph
- Notice images
- Notices appearing in Feed
- Member login on website
- Replacing NestJS with Supabase-direct CRUD
- Orange branding

---

## Stages C1–C4 — Coach identity, programs, buddies (app-only)

> Added September 2026. Phase 3 (booking) is **parked** until session-link analysis (#11).

### Stage C1 — Coach identity + Coach home ✅

| ID | Task | Notes |
|----|------|-------|
| C1.1 | `staffInvite` provisions `User` + roster + JWT metadata | Done |
| C1.2 | `POST /auth/coach/login` + `GET /auth/coaches` | Done |
| C1.3 | Flutter “I’m a coach” login toggle | Done |
| C1.4 | Coach home shell for `coach`/`admin` roles | Done |

### Stage C2 — Gym programs + certify + directory ✅

| ID | Task | Notes |
|----|------|-------|
| C2.1 | Publish/unpublish routines (`source=coach_program`) | Done |
| C2.2 | `GET /workouts/programs` + certify queue | Done |
| C2.3 | Flutter publish UX + gym programs on Train | Done |
| C2.4 | Member Home coaches directory | Done |

### Stage C3 — Booking (parked)

| Topic | Banked decision |
|-------|-----------------|
| Type | 1:1 only |
| Slots | One-off calendar slots |
| Duration | 60 min default (per-slot override) |
| Book window | 14 days ahead |
| Cancel | Either party until start |
| App-only | Yes |
| Session link | TBD (#11) — do not implement until analyzed |

### Stage C4 — Gym buddies + in-app notifications ✅

| ID | Task | Notes |
|----|------|-------|
| C4.1 | Schema: buddy links, session participants, app_notifications | Done |
| C4.2 | Buddy + notifications APIs | Done |
| C4.3 | Flutter buddies + shared session start | Done |
| C4.4 | Real notifications inbox | Done |

**Apply DB:** prisma migrate `20260918120000_coach_buddies_notifications` + `supabase/migrations/013_coach_buddies_notifications.sql`.

---

## Suggested calendar (flexible)

| Week | Focus |
|------|--------|
| 1 | Stages 1–2 (notices end-to-end) |
| 1–2 | Stage 3 (device verify; fix bugs) |
| 2–3 | Stages 4–5 (portal + roster) |
| 3–4 | Stage 6 (notices admin + moderation) |
| 4–5 | Stage 7 (marketing + deploy) |
| now | Stages C1 / C2 / C4 (coach + buddies); C3 parked |
| later | Stage 8 (push); Stage C3 after #11 |

---

## Definition of “pilot ready”

- [ ] Coach posts a notice in the app → members see it on Home + Notices
- [ ] Admin logs into `tether-web`, imports CSV, adds a member manually, posts/edits a notice
- [ ] Member completes workout, shares, post shows in gym-wide feed on device
- [ ] No placeholder notices left on Home
- [ ] Coach can log in via “I’m a coach”, publish a gym program, certify from queue
- [ ] Members see coaches directory + gym programs; buddies + in-app notifications work
- [ ] Marketing page optional for first private pilot; required for public gym sales

---

## Start here

**Current focus:** apply coach/buddy migrations; smoke coach login → publish → buddy session.

Cloud Run / production deploy remains paused until coach/buddy smoke is green.

When implementing, update this file’s checkboxes mentally (or tick in PRs) and keep `docs/CODEBASE_OVERVIEW.md` status section in sync after each stage.
