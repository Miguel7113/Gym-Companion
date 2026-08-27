# Tether — Issues Tracker

> Last updated: 2026-07-22
> Format: **[STATUS]** — `file` — description

## STATUS KEY
- 🔴 OPEN — not yet fixed
- 🟡 IN PROGRESS — being worked on now
- 🟢 FIXED — resolved in codebase
- 🔵 DEFERRED — shelved by decision

---

## CRITICAL (app-breaking)

### AUTH-001 🟢 FIXED
**`/auth/claim-session` endpoint missing in NestJS**
- File: `gym-app-backend/src/auth/auth.controller.ts`
- `main.dart` `_completeClaim()` calls `POST /auth/claim-session` after magic link login but the endpoint was never built. Auth via OTP code path worked but magic link path silently failed.
- Fix: Added `POST /auth/claim-session` to controller + service. Takes `{ email, phone }`, finds roster match, creates/finds users row, injects JWT claims (gym_id, member_id, role, display_name), returns `{ accessToken, refreshToken }`.

### AUTH-002 🟢 FIXED
**Connection pool timeout — `listEquipments` & `listBodyParts` doing full table scans**
- File: `gym-app-backend/src/workouts/workouts.service.ts`
- `findMany({ select: { equipments: true } })` on 873-row exercise table over Supabase pooler with `connection_limit=1` times out at 10s. This causes the exercise picker to stay on loading spinner indefinitely.
- Fix: Replaced full `findMany` with `queryRaw` DISTINCT unnest queries. Also raised `connection_limit` from 1 to 5 in DATABASE_URL.

### WORKOUT-001 🟢 FIXED
**"Couldn't start" when pressing BEGIN in workout builder**
- File: `gym_app_mobile/lib/features/workouts/screens/workout_builder_screen.dart`
- Root cause: `_completeClaim` (magic link path) failed silently, leaving `gymId = ''` in JWT. `createSession` requires gymId in the NestJS request. Once AUTH-001 is fixed and claim-session returns valid tokens, gymId is populated and BEGIN works.
- Fix: Dependent on AUTH-001.

### WORKOUT-002 🟢 FIXED
**Exercise list empty when opening "Add Exercise"**
- File: `gym_app_mobile/lib/features/workouts/screens/exercise_picker_sheet.dart`
- `_loadMeta()` calls `listEquipments()` which times out (see AUTH-002). The single `Future.wait([...])` call means all four loads fail together — `_loadingMeta` stays `true` and the body part grid never appears.
- Fix: Split `_loadMeta` so `listBodyParts` and `listEquipments` each fail independently. Body parts load even if equipments timeout. The grid appears with `_allEquipments = []` in the worst case.

---

## HIGH (major feature broken)

### PROFILE-001 🟢 FIXED
**Profile shows `member@example.com` instead of real name**
- File: `gym_app_mobile/lib/features/profile/screens/profile_screen.dart`
- `_ProfileHero` had hardcoded string `'member@example.com'` instead of reading from `currentUserProvider`.
- Fix: Read `currentUserProvider` in `_ProfileHero`, display `displayName ?? email ?? 'Member'`.

### PROFILE-002 🟢 FIXED
**"MEALS LOGGED" stat still shown in profile stats bento**
- File: `gym_app_mobile/lib/features/profile/screens/profile_screen.dart`
- Food feature was shelved but `_StatsBento` still shows `MEALS LOGGED` tile with restaurant icon.
- Fix: Replaced with `SETS THIS WEEK` using `Symbols.bolt` icon.

### WORKOUT-003 🟢 FIXED
**Equipment filter selection not passed to ExercisePickerSheet**
- File: `gym_app_mobile/lib/features/workouts/screens/workouts_screen.dart`
- `_openExerciseList()` computes `equipment` from `_selectedEquipment` but never passes it to `ExercisePickerSheet.show()`. The picker opens with no pre-selected equipment.
- Fix: Added `initialEquipment` parameter to `ExercisePickerSheet.show()` and wired it through.

### HOME-001 🟢 FIXED
**Trainer tip card is static — tap does nothing**
- File: `gym_app_mobile/lib/features/home/screens/home_screen.dart`
- `_PhotoTrainerTip` is a plain `Container` with no gesture handler. User expectation: tapping should open a dialog with more tips.
- Fix: Wrapped in `GestureDetector`, shows a `showModalBottomSheet` with a rotating list of trainer tips (5 tips). Tips cycle through on each open.

---

## MEDIUM (UX degraded)

### GIF-001 🔵 DEFERRED
**Exercise "GIFs" are static images, not animated**
- Source: `free-exercise-db` hosts static JPG/PNG via jsDelivr CDN despite the field being named `gifUrl`.
- Decision: No fix needed in code — images load correctly as static previews. The demo label in `ExerciseDetailScreen` can be updated from "GIF" to "DEMO" in a future polish pass.

### AUTH-003 🔵 DEFERRED — partial
**Magic link login is slow (~3–5s delay after app opens)**
- Root cause: `_completeClaim` makes an extra NestJS API call after the Supabase session arrives. Supabase deep link processing + JWT refresh adds latency.
- Partial fix: Once AUTH-001 is live, the endpoint exists and responds properly. Further optimization (pre-fetch gymId during gym selection, cache roster lookup) can be done in a future sprint.

### WORKOUT-004 🔴 OPEN
**Equipment filter in picker sheet passes only first item to API**
- File: `gym_app_mobile/lib/features/workouts/screens/exercise_picker_sheet.dart`
- When multiple equipment items are selected, only `_selectedEquipment.first` is sent to the API. The rest are filtered client-side with `every()` intersection logic — which means if a user selects "barbell" AND "cable" they get exercises that require BOTH, not EITHER.
- Suggested fix: Change multi-equipment logic to OR (union): fetch once with no equipment filter, then filter locally by `any()` instead of `every()`.

### SOCIAL-001 🔴 OPEN
**Social feed uses placeholder avatars (pravatar.cc)**
- Files: `gym_app_mobile/lib/features/social/screens/feed_screen.dart`, `home_screen.dart`
- Should use the user's real avatar from Supabase storage once profile photo upload is built.

---

## LOW (polish)

### HOME-002 🔴 OPEN
**Gym Notices section on home page uses hardcoded placeholder data**
- File: `gym_app_mobile/lib/features/home/screens/home_screen.dart`
- `_ModernAnnouncementSection` shows static notice cards. Should pull real notices from `gym_notices` table via `homeDataProvider` once the gym website/CMS is live.
- Deferred until website is up.

### HOME-003 🔴 OPEN
**`streakDays` stat always shows 0**
- File: `gym_app_mobile/lib/features/home/providers/home_data_provider.dart`
- Streak calculation not yet implemented in backend. Needs a `GET /workouts/streak` endpoint that counts consecutive days with sessions.

### PROFILE-003 🔴 OPEN
**Settings screen items are placeholder (all `TODO` on tap)**
- File: `gym_app_mobile/lib/features/profile/screens/profile_screen.dart`
- Edit Profile, Notifications, Privacy, Help all have `// TODO: route` with no navigation wired up.

### AUTH-004 🔴 OPEN
**`display_name` not stored during magic link signup path**
- File: `gym_app_mobile/lib/main.dart`
- Magic link flow doesn't prompt for display name. `_completeClaim` has no `displayName` — NestJS falls back to `match.memberName` from gym_roster. If roster entry has no name, display_name is null.
- Fix: During `requestOtp`, capture the user's name input and store it. Pass `displayName` from the stored input when calling `/auth/claim-session`.

---

## BACKEND

### BE-001 🟢 FIXED
**`connection_limit=1` in DATABASE_URL causes pooler timeouts**
- File: `gym-app-backend/.env`
- Supabase pooler with `connection_limit=1` means all concurrent Prisma queries queue and the 10s timeout fires under any load.
- Fix: Changed to `connection_limit=5`.

### BE-002 🟢 FIXED
**`listEquipments()` and `listBodyParts()` do full table scans via ORM**
- File: `gym-app-backend/src/workouts/workouts.service.ts`
- Loading all 873 exercises into memory just to extract distinct string arrays is wasteful.
- Fix: Using `$queryRaw` with `unnest + DISTINCT` to let Postgres do the work in one fast query.

### BE-003 🔴 OPEN
**No `/workouts/streak` endpoint**
- Needed by `HOME-003` to calculate and return the user's consecutive workout day streak.

### BE-004 🔴 OPEN
**No pagination on `listExercises`**
- Currently capped at `take: 500`. Should add cursor/offset pagination for future-proofing.

---

## DECISIONS LOG

| Decision | Outcome |
|---|---|
| Magic link vs OTP code for email | Kept magic link. Supabase email OTP requires extra config. Deep link works on Android. |
| Food / Nutrition tab | Shelved entirely. Food tables dropped (migration 007). 4 tabs: HOME / TRAIN / FEED / PROFILE. |
| App name | Renamed Pulse → Tether. Slogan: "Your gym, always within reach." |
| Exercise GIFs | `free-exercise-db` images are static JPGs despite `gifUrl` field name. No fix needed — images load fine. |
| Exercise data source | 873 exercises from `free-exercise-db` (MIT). Rejected `oss.exercisedb.dev` — broken pagination. |
| Database connection | NestJS → Supabase pooler direct. Rejected local Postgres because phone can't reach localhost. |
| Gym notices | Tied to website CMS. Deferred until website is live. |
| Social feed | Members + coaches post from individual accounts. Gym notices shown separately on home page. |
