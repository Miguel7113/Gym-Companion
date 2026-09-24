# TETHER — Plan & Explanation
## Product decisions aligned to the current codebase

> Updated September 2026. Older sections that assumed multi-gym, following, or Flutter→Supabase-direct are superseded below.

---

## 1. Current state (accurate)

Tether is past “empty MVP.” The workout engine, roster auth, and gym-wide social feed are implemented against NestJS. The website is not started.

### What works well

- Offline-first workout tracking (Drift + sync) with Hevy-style session UI
- Roster-gated auth (OTP + password flows) via NestJS + Supabase Auth
- Four-tab navigation (Home, Train, Feed, Profile)
- Gym-wide feed: likes, comments, flag, workout share, coach certification
- Member profiles (same gym)
- Staff API hooks: stats, members, roster, staff posts
- Consistent dark + neon lime (`#C3F400`) visual language

### What still needs work before a gym pilot

- Gym notices + Home coach tips are **hardcoded placeholders** (no real API yet)
- Device verification of feed auth refresh + pending share queue
- Push notification delivery (`push_tokens` exists; sending does not)
- Next.js admin portal + marketing site (**not built**)
- Optional: realtime feed (polling is fine for v1)

### Stale claims in older drafts (ignore)

| Old claim | Reality |
|-----------|---------|
| Social tables not wired to UI | Feed is live via NestJS |
| Share-to-feed does not exist | `POST /social/workout-sessions/:id/share` + app flow |
| RLS missing | Policies exist; app still uses NestJS |
| Must build following for feed | Product chose gym-wide feed |
| Must ship multi-gym before launch | Single `users.gym_id` for v1 |

---

## 2. Key design decisions (locked for v1)

### Why NestJS stays in the middle

Workouts, social, roster, and staff checks are non-trivial. NestJS + Prisma gives one place for validation, staff gates, and sync-friendly APIs. Flutter and the future website both call NestJS. Supabase remains Auth + Storage + hosted Postgres (+ RLS as backup).

### Why one gym per user (for now)

`users.gym_id` is simple and matches how the app ships today. Multi-gym (`user_gyms`) can wait until a real customer needs travel/home gym switching. Do not block the website on this.

### Why gym-wide feed (no follows)

For a single gym community, newest-first is clearer and needs less empty-state education. Following can be revisited if the feed becomes noisy at large member counts.

### Why coaches live in the same app

Coaches/staff are detected via `gym_staff` / JWT `isStaff`. Same Flutter app gets certify + staff post capabilities; admins get a web dashboard later for roster/notices/moderation.

### Why Next.js for the website

Dashboards, tables, CSV, and SEO marketing fit React/Next better than Flutter Web. The portal is **not** a second backend.

### Brand

Lime `#C3F400` on dark surfaces. Orange accents in early website mock plans are obsolete.

### Images per post

v1 supports **one** optional image on a workout share (`image_path` / `image_url`). Multi-image can wait.

---

## 3. Architecture (app ↔ website ↔ DB)

```
Flutter (members/coaches)
        │
        │  JWT
        ▼
   NestJS API  ◄──── Next.js admin (staff)   [planned]
        │
        ▼
 PostgreSQL (Supabase) + Auth + Storage
```

- Members never bypass NestJS for workouts/social.
- Staff website uses `POST /auth/staff/login` and staff-guarded routes.
- RLS policies protect against accidental direct client access; they are not the primary product API.

---

## 4. How the social feed works (as built)

1. Member finishes a workout → optionally shares → NestJS creates a `posts` row linked to `workout_session_id`.
2. Feed query returns posts for that `gym_id`, newest first (not deleted).
3. Likes / comments / flags are separate tables with NestJS endpoints.
4. Any staff/coach in the gym can certify a post once (`coach_certifications`).
5. Staff can also create posts directly (`POST /social/posts`) for announcements.

**Not built:** following graph, pinned notices table, realtime subscriptions.

**Empty feed:** CTA should push users to Train / complete a workout and share.

---

## 5. Auth flows

### Members

1. Gym selects active gym
2. Roster check (`/auth/check-member`)
3. OTP and/or password via NestJS
4. User row created/linked; JWT metadata includes `gym_id`, `member_id`, `role`
5. Flutter stores Supabase session; ApiClient attaches Bearer token

### Staff (admin portal — planned UI)

1. Row in `gym_staff`
2. `POST /auth/staff/login`
3. NestJS staff guards on gym management routes

Random public signup is intentionally blocked.

---

## 6. Security notes

1. Never ship the service role key to Flutter or Next.js public bundles
2. Keep gym isolation in NestJS queries (`WHERE gym_id = …`)
3. Treat RLS as a second line of defense, not a reason to skip NestJS
4. Staff actions require `gym_staff` / `isStaff`, not “any authenticated user”

---

## 7. Implementation phases (revised)

### Phase A — Finish mobile core

- Notices model + API + wire Home/Notices
- Replace hardcoded tips
- Verify share/feed on device
- Minimal push if needed for pilot

### Phase B — Admin portal MVP

- Scaffold `tether-web`
- Staff login, stats, members, roster
- Notices + moderation once notices exist

### Phase C — Marketing site

- Landing / pricing / for-gyms
- Lime brand composition
- Deploy next to NestJS

### Phase D — Later

- Analytics aggregations
- Realtime (optional)
- Multi-gym / follows **only if product requires**

Detailed website steps: `docs/archive/tether-plan/TETHER_Build_Plan.md`.

---

## 8. Critical pitfalls to avoid

1. **Rewriting the schema** to match the old `profiles`/`follows` docs
2. **Bypassing NestJS** from the website for social/workouts
3. **Building following** before notices and admin tools
4. **Orange brand drift** away from the shipped Flutter app
5. **Assuming Home notices are real** — they are still placeholders

---

## 9. Locked website / product decisions (Sep 2026)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Notices | Dedicated **`gym_notices`** table; shown on **Home + Notices** (and later push) — **not** in the social feed |
| 2 | Who uses the website | **Staff/admin portal only** (no member web login in v1) |
| 3 | Multi-gym | **Defer (A)** — keep `users.gym_id`; no `user_gyms` for v1 |
| 4 | Following | **Gym-wide feed** — no following system in v1 |
| 5 | Build order | **Admin portal before marketing**; after notices + **device-verify feed/share** |
| 6 | Monorepo layout | **`tether-web/` at repo root** |
| 7 | Notice authors | **Coaches (in the app)** can create notices; **admins use the website** |
| 8 | Notice fields v1 | **Pin + tags**; **no images yet** |
| 9 | Notice delete | **Soft-delete** (recommended — see below) |
| 10 | Roster | **CSV import + manual add** in admin MVP |
| 11 | Push notifications | **After** website MVP |

### Roles split (chosen)

| Role | Where they work | Typical powers |
|------|-----------------|----------------|
| Member | Flutter app | Workouts, gym-wide feed, read notices |
| Coach | Flutter app | Same as member + create notices + certify posts (+ staff social posts if already allowed) |
| Admin | **Website** (`tether-web`) | Roster CSV/manual, gym settings, notices management, moderation, stats |

Coaches are **not** the primary website users in v1. Admins are. NestJS must still authorize notice **create** for coach (app) and admin (web).

### Notices model (chosen)

- Table: `gym_notices`
- Surfaces: Home strip, Notices screen — **never auto-posted to Feed**
- v1 fields: title, body, tag, `is_pinned`, author, timestamps, soft-delete flag
- Images: **later**
- Soft-delete: yes — hide from members, keep row for admin undo/audit; hard delete is harder to recover from accidental wipes

### Build sequence (chosen)

1. `gym_notices` backend + Flutter Home/Notices (+ coach compose in app)
2. Device-verify feed auth + workout share
3. Scaffold `tether-web/` — admin portal (roster CSV + manual, notices, stats, moderation)
4. Marketing site
5. Push notifications

---

## 10. Related docs

| Doc | Use |
|-----|-----|
| `docs/CODEBASE_OVERVIEW.md` | Repo map + status |
| `docs/WEBSITE_PLAN.md` | Portal scope |
| `docs/archive/tether-plan/TETHER_Database_and_API.md` | Real schema + routes |
| `docs/archive/tether-plan/TETHER_Developer_Guide.md` | Next.js how-to |
| `tether_technical_implementation.md` | Technical notes (NestJS-aligned) |

---

## 11. Multi-gym — what the question actually means

**Today:** each row in `users` has exactly one `gym_id`. When you log in, you are a member of that gym only. Workouts, feed, roster, and profile all assume that single gym.

**Multi-gym would mean:** one person (one auth account / one phone or email) can belong to **more than one gym**, and switch which gym they are “in” inside the app.

### Concrete examples

| Scenario | Single-gym (current) | Multi-gym |
|----------|----------------------|-----------|
| Member trains at Gym A and visits Gym B while traveling | Needs a second account or re-claim under Gym B | Same login; pick Gym B; see B’s feed/roster rules |
| Coach works at two franchise locations | Two staff records / awkward | One person, two gym memberships with roles |
| Someone leaves Gym A for Gym B | Overwrite `gym_id` (history stays under old gym_id in DB but UX is messy) | Deactivate A membership, activate B |

### What would change technically

- Add a junction like `user_gyms (user_id, gym_id, role, is_active)`
- JWT / session must carry **selected** `gym_id` (not only “the” gym)
- Every NestJS query already scopes by gym — still fine, but auth claim injection and Flutter gym picker after login must change
- Roster matching becomes “email on Gym A roster and Gym B roster” as two memberships
- Feed stays gym-scoped either way (you never mix Gym A posts into Gym B)

### What multi-gym does *not* mean

- It is **not** required for the admin portal (staff already have `gym_staff.gym_id`)
- It is **not** the same as “many gyms in the database” — you already support many gym tenants
- It is **not** required for notices, roster CSV, or marketing

### Recommendation framing

- **Defer** if every pilot member has one home gym and coaches don’t need dual membership yet (most common for first launch).
- **Plan schema now** only if you already know travelers / multi-location coaches are a selling point for the first paying gyms.

You can ship admin + notices + marketing with **single-gym members**. Multi-gym is a membership/auth refactor, not a website blocker.

---

## 12. Following — decided

**v1: gym-wide feed only.** No follow graph.

- Feed = all non-deleted posts in the member’s gym, newest first
- Notices stay on Home / Notices (and later push), not in the feed
- Revisit only if a live gym’s feed becomes too noisy (optional later: “Following | Gym” tabs)

---

## 13. Soft-delete for notices — recommendation

**Yes — soft-delete is better for notices.**

| | Soft-delete | Hard delete |
|--|-------------|-------------|
| Accidental wipe | Admin can restore | Gone |
| Audit (“who removed what”) | Keep row + `deleted_at` / `deleted_by` | Lost |
| Member UX | Filtered out of Home/Notices | Same |
| DB cost | Tiny for notice volume | Slightly cleaner |

Use `deleted_at` (nullable). Member GETs filter `deleted_at IS NULL`. Admin can list including deleted and restore. Hard delete can stay as a rare “purge” later if needed.

---

## 14. Multi-gym — decided

**v1: Defer (option A).** Keep single `users.gym_id`.

- Many gym **tenants** on the platform already work
- Members/coaches do not switch between multiple personal memberships yet
- Revisit only when a real gym needs travel/home dual membership or multi-location coaches under one login

See §11 for the original explanation.
