# Phase 2 Plan — App Redesign + Social Layer
### Gym Companion | Dawn Digital

> **⚠️ NOTE:** This document contains historical planning from early 2024.  
> **Current Status (Oct 2024):** Most of Phase 2 is now complete. See `docs/EXECUTION_PLAN.md` for current priorities.
> 
> **Food/Nutrition Feature:** Shelved indefinitely (migration 008 dropped all food tables). Sections mentioning food below are kept for historical context only.

---

## Current State Audit (Historical — as of Feb 2024)

### What was working (Phase 1 backend ✅)
- Auth flow: OTP request/verify, staff login, roster matching — all wired up
- Workout sessions, sets, exercises — full CRUD in backend
- ~~Food logs, food search, Open Food Facts proxy — backend complete~~ **(REMOVED — migration 008)**
- Prisma migration run in Supabase
- Seed data: pilot gym, 873 exercises from free-exercise-db

### What was broken / incomplete (Historical)

> **Note:** Most items in this list have been fixed. This is kept for historical reference.

| Issue | Location | Status (Oct 2024) |
|-------|----------|-------------------|
| `SKIP_LOGIN_FOR_TESTING = true` | `main.dart` | ✅ FIXED — now false |
| Token not persisted across app restarts | `ApiClient` | ✅ FIXED — Supabase SDK handles persistence |
| ~~`deleteFoodLog()` throws `UnimplementedError`~~ | ~~`food_service.dart`~~ | ❌ N/A — Food feature removed |
| ~~`updateFoodLog()` throws `UnimplementedError`~~ | ~~`food_service.dart`~~ | ❌ N/A — Food feature removed |
| `WorkoutService.updateSession()` calls `PUT` | `workout_service.dart` | ✅ FIXED — Uses PATCH |
| `WorkoutService.updateSet()` endpoint missing | `workout_service.dart` | ✅ FIXED — Endpoint added |
| `WorkoutService.deleteSession()` / `deleteSet()` | `workout_service.dart` | ✅ FIXED — DELETE endpoints exist |
| All stats on Home + Profile screens hardcoded `0` | `home_screen.dart`, `profile_screen.dart` | ✅ FIXED — Real API data |
| ~~`userId = 'user_id_placeholder'`~~ | ~~`food_screen.dart`~~ | ❌ N/A — Food feature removed |
| No session persistence | `auth_service.dart` | ✅ FIXED — Supabase handles it |
| No `social/` feature folder | mobile app | ✅ FIXED — Fully implemented |
| No `ai_companion/` feature folder | mobile app | ⏸️ DEFERRED — Phase 3 |
| No push notification setup | mobile + backend | 🔴 TODO — High priority |
| ~~`foods` table missing `updatedAt`~~ | ~~Prisma schema~~ | ❌ N/A — Food tables dropped |
| No Row Level Security on Supabase | Supabase config | ✅ FIXED — Migration 009 |

---

## ⚠️ HISTORICAL CONTENT BELOW

The sections below are kept for reference but reflect early 2024 planning. Many items have been implemented or decisions reversed (e.g., food feature shelved).

For current implementation status and next steps, see:
- `docs/EXECUTION_PLAN.md` — current sprint priorities
- `docs/CODEBASE_OVERVIEW.md` — what exists today
- `docs/ISSUES.md` — known bugs and decisions log

---

## Database — What to Add and When (Historical)

### Add Now (before Phase 2 work starts)

These close gaps in Phase 1 that are already causing bugs, plus lay the foundation for Phase 2.

**1. Supabase: Run the pending Prisma migration additions**

Add these fields/indexes to existing tables via Prisma schema update + migrate:

```
users:         add updatedAt (already has it ✅)
foods:         add updatedAt (missing — inconsistent)
gym_staff:     add updatedAt (missing)
workout_sets:  add updatedAt (missing)
```

**2. New table: `user_sessions`** — token persistence
Stores refresh tokens so users stay logged in across app restarts.

```
id, user_id, refresh_token, device_info, created_at, last_used_at, expires_at
```

**3. New table: `push_tokens`** — FCM device tokens for Phase 2 notifications
Small table, costs nothing, painful to retrofit later.

```
id, user_id, device_token (unique), platform (ios/android), created_at, updated_at
```

### Add for Phase 2 (Social Layer)

**4. `posts`** — gym-scoped feed entries
```
id, gym_id, user_id, content, image_url, achievement_type (pr/streak/milestone/null),
is_flagged, created_at, updated_at
```

**5. `post_likes`** — simple like tracking
```
id, post_id, user_id — UNIQUE(post_id, user_id), created_at
```

**6. `post_comments`** — threaded comments on posts
```
id, post_id, user_id, content, created_at, updated_at
```

**7. `user_achievements`** — tracks milestones for auto-posting and streak display
```
id, user_id, gym_id, achievement_type, value (e.g. "100kg bench"), earned_at
```

### Add for Phase 3 (AI + Payments)

**8. `ai_conversations`** — one per user
```
id, user_id, created_at
```

**9. `ai_messages`** — individual turns
```
id, conversation_id, role (user/assistant), content, token_count, created_at
```

**10. `subscriptions`** — premium tier tracking
```
id, user_id, gym_id, tier, status, payment_provider (mpesa/stripe),
provider_reference, started_at, expires_at, created_at
```

**11. `payment_events`** — webhook audit log
```
id, user_id, provider, event_type, payload (jsonb), created_at
```

**12. `import_jobs`** — data import queue (Strong/Hevy/Apple Health)
```
id, user_id, source_type, status, raw_file_url, rows_processed, rows_total, error_log, created_at
```

---

## Supabase Config Checklist (do this session)

### Row Level Security (RLS)
Every table needs RLS policies so that even if someone bypasses your API, they can't read other users' data directly. Key policies:

- `users`: users can only read/update their own row
- `workout_sessions`: users can only see sessions where `user_id = auth.uid()` (mapped via `auth_provider_id`)
- `workout_sets`: inherit from session ownership
- `food_logs`: users can only see their own logs
- `gyms`: public read (anyone can list gyms for the selection screen)
- `gym_roster` / `gym_staff`: staff-only read/write
- `exercises`: public read, users can insert custom (where `created_by_user_id = auth.uid()`)
- `foods`: public read, users can insert custom

> Note: Since your backend uses the service role key (bypasses RLS), these policies only protect against direct DB access, not your API. But they're still worth setting up for production hygiene.

### Storage Buckets
Set these up now so you're not retrofitting later:

| Bucket | Access | Used for |
|--------|--------|---------|
| `avatars` | Authenticated users only | Profile pictures |
| `gym-assets` | Public read, staff write | Gym logos, banners |
| `post-images` | Authenticated users write, public read | Social feed photos |
| `import-files` | Authenticated users only | CSV / Apple Health uploads |

### Auth Settings
- Email OTP: enabled ✅ (already configured)
- Phone OTP: configure with Twilio when ready for SMS
- JWT expiry: set to 3600s (1 hour) — short enough to be safe, your app should auto-refresh using the refresh token
- Disable "email confirmation required" — OTP IS the confirmation

---

## App Redesign — What Needs to Change

### Core problems with current UI
1. **Feels like a demo, not a product** — hardcoded zeros everywhere, placeholder names, no real data flowing to home screen
2. **No auth state management** — token dies on restart, user context not available to screens
3. **Navigation is flat** — 4 tabs with no visual hierarchy or personality
4. **Missing packages** for Phase 2 — no image picker, no barcode scanner, no push notification handler, no Supabase client SDK

### What to redesign

**Navigation**
~~Add a 5th tab for Social (Phase 2).~~ **UPDATE:** Social is tab 3 of 4 tabs. Consider renaming and reordering:
- Home (member view) / Coach Dashboard (staff view) ✅
- Train (workouts) ✅
- Feed (social) ✅
- Profile ✅
- ~~Food~~ **(REMOVED)**

**Theme**
Current theme is generic Material 3. For a gym app targeting Nairobi users:
- Dark mode as default (gyms are dimly lit)
- High contrast accent color — the current indigo (`#4F46E5`) works; could go bolder
- Custom font (Google Fonts — Poppins or Inter) — no licensing cost, one line in pubspec
- Heavier use of cards with subtle gradients on key CTAs
- Gym logo/branding surfaced on home screen using the `primaryColor` field already in the DB

**Home Screen**
~~Currently all static.~~ **UPDATE (Oct 2024):** Fully implemented. Should show:
- Greeting with user's actual display name (from auth state) ✅
- Today's workout (if one exists) or a "Start Workout" CTA ✅
- ~~Calorie ring for today~~ **(REMOVED — no food feature)**
- Recent post from their gym's feed (Phase 2 hook) ✅
- Streak counter ~~(requires `user_achievements` table)~~ ✅

**Profile Screen**
- Show real user data (name, email, gym name) from auth state ✅
- ~~Working logout (currently `// TODO`)~~ ✅
- Subscription tier badge ⏸️ (Phase 3)
- Stats pulled from real DB queries (workout count, streak) ✅

**Workouts Screen**
- ~~Remove the history screen being embedded — give it its own tab treatment or a full sheet~~ ✅
- ~~Make the "Start Workout" button more prominent~~ ✅

~~**Food Screen**~~
~~- Calorie progress bar at top (calories logged vs goal)~~
~~- Macro rings (protein/carbs/fat)~~
~~- Fix the broken delete/update calls~~
**REMOVED** — Food feature shelved (migration 008)

---

## Packages to Add (Historical)

> **UPDATE (Oct 2024):** Most of these are now in `pubspec.yaml`. Food/barcode scanner removed.

For Phase 2 redesign, ~~add~~ added to `pubspec.yaml`:

```yaml
# Auth persistence
~~flutter_secure_storage: ^9.0.0~~   # Not needed — Supabase SDK handles it

# Supabase (consider using SDK directly for real-time features)
supabase_flutter: ^2.3.0  ✅ ADDED

# UI
google_fonts: ^6.1.0  ✅ ADDED
cached_network_image: ^3.3.1  ✅ ADDED (v4.0.0)

# Camera / media
image_picker: ^1.0.7  ✅ ADDED
~~mobile_scanner: ^4.0.1~~  # NOT ADDED — no food feature

# Push notifications
firebase_core: ^2.27.1  ❌ TODO
firebase_messaging: ^14.7.20  ❌ TODO
flutter_local_notifications: ^17.0.0  ❌ TODO

# Connectivity
connectivity_plus: ^5.0.2  ✅ ADDED (v6.0.3)

# Misc
~~intl: ^0.19.0~~  # Not needed yet
~~timeago: ^3.6.1~~  # Not needed — using custom relative time
```

---

## Build Sequence (Historical — mostly complete)

### ~~Step 1 — Foundation fixes (do first, unblocks everything else)~~
1. ~~Set up Supabase RLS policies + storage buckets~~ ✅ DONE
2. ~~Add `push_tokens` + social tables to Prisma, run migration~~ ✅ DONE
3. ~~Add `flutter_secure_storage` + wire up token persistence~~ ✅ DONE (Supabase SDK)
4. ~~Wire auth state to screens~~ ✅ DONE — `currentUserProvider`
5. ~~Fix the broken endpoints: add DELETE for sessions/sets~~ ✅ DONE / ~~food logs~~ N/A
6. ~~Fix `PUT` vs `PATCH` mismatch in workout service~~ ✅ DONE

### ~~Step 2 — App redesign~~
7. ~~Add Google Fonts, update theme (dark default, custom typography)~~ ✅ DONE
8. ~~Redesign Home screen with real data~~ ✅ DONE / ~~calorie ring~~ N/A
9. ~~Fix Profile screen (real name/email, working logout, real stats)~~ ✅ DONE
10. ~~Add barcode scanner to food flow~~ ❌ N/A — Food feature removed
11. ~~Add image picker to profile~~ ✅ DONE

### ~~Step 3 — Phase 2 social~~
12. ~~Build `social/` feature: posts, likes, comments~~ ✅ DONE
13. ~~Build Social tab (gym-scoped feed)~~ ✅ DONE
14. ~~Auto-post achievements (new PR, streak milestone)~~ ✅ DONE
15. Wire up push notifications (FCM setup + backend trigger) ❌ TODO

### Step 4 — Admin portal
16. Build basic Next.js admin portal: member list, roster upload, pending approvals, feed moderation ⏸️ IN PROGRESS
17. This is the thing you need to show gym owners — build it before Phase 3 ⏸️ IN PROGRESS

---

---

## Phase 2 Additions: Nutrition API, Workout API, Offline Database

### Nutrition & Food API (expand existing food module)

**Current state:** Open Food Facts search + barcode lookup + custom food entry. Basic.

**What to add in Phase 2:**

1. **Barcode scanner in-app** — replace the placeholder with `mobile_scanner` package (Google ML Kit on-device, works offline). The scan triggers `GET /food/barcode/:code` on the backend.

2. **Nutritionix API fallback** — Open Food Facts has poor coverage for packaged Kenyan foods. Add Nutritionix ($49/mo) as a fallback when OFD returns no result. Backend tries OFD first → Nutritionix second → returns combined results. The Flutter app doesn't need to know which source was used.

3. **Calorie goals** — Add a `calorie_goal` and `protein_goal` column to the `users` table. The food screen's progress ring becomes meaningful. Default to 2000 kcal / 150g protein until user sets their own.

4. **Meal templates** — New table: `meal_templates` (user_id, name, [food items]). Lets users save a "standard breakfast" and log it in one tap. High-leverage for retention.

5. **Water tracking** — Simple counter, no new table needed. Store daily water logs in a `water_logs` table (user_id, logged_at, amount_ml). Light feature, high visibility on the home screen.

6. **Food log update/delete** — Currently `UnimplementedError`. Add `PATCH /food/logs/:id` and `DELETE /food/logs/:id` to the backend (soft delete via `deleted_at`).

**Schema additions for nutrition:**
```sql
-- Add to users table
ALTER TABLE users ADD COLUMN calorie_goal INTEGER DEFAULT 2000;
ALTER TABLE users ADD COLUMN protein_goal_g INTEGER DEFAULT 150;

-- New table
CREATE TABLE water_logs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(id) NOT NULL,
  logged_at TIMESTAMPTZ NOT NULL,
  amount_ml INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE meal_templates (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(id) NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE meal_template_items (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id TEXT REFERENCES meal_templates(id) ON DELETE CASCADE NOT NULL,
  food_id TEXT REFERENCES foods(id) NOT NULL,
  quantity_g NUMERIC(10,2),
  meal_type TEXT
);
```

---

### Workout API (expand existing workouts module)

**Current state:** Create session, add sets, list history, progress by exercise. Missing DELETE and UPDATE for sessions/sets.

**What to add in Phase 2:**

1. **Delete session** — `DELETE /workouts/sessions/:id` → soft delete via `deleted_at`. Backend already has the column after migration 002.

2. **Delete set** — `DELETE /workouts/sets/:id` → soft delete. All list queries need `WHERE deleted_at IS NULL`.

3. **Update set** — `PATCH /workouts/sets/:id` → update reps/weight/rpe on an existing set.

4. **Workout templates** — New table: `workout_templates` + `workout_template_exercises`. Staff or users can save a "Push Day" template that pre-fills the exercise list for a new session. Big retention feature — makes starting a workout feel fast.

5. **Personal records detection** — On every `addSet`, the backend should check if the weight is a new PR for that exercise for that user. If yes, create a `user_achievements` row (type: `pr`) and optionally auto-create a post. This is the hook for the social feed.

6. **Streak tracking** — A daily cron (or on-login trigger) checks if the user logged a workout yesterday. If yes, increment streak. If no, reset. Store current streak in `users` table (`current_streak_days`, `longest_streak_days`). Show on home screen and profile.

7. **Workout summary** — `GET /workouts/sessions/:id/summary` → returns total volume (sets × reps × weight), time under tension, muscles worked. Used on the post-workout summary screen.

**Schema additions for workouts:**
```sql
-- Add to users table
ALTER TABLE users ADD COLUMN current_streak_days INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN longest_streak_days INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN last_workout_date DATE;

-- Workout templates
CREATE TABLE workout_templates (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(id),     -- NULL = gym-provided template
  gym_id TEXT REFERENCES gyms(id),
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT false,       -- gym staff can make public templates
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE workout_template_exercises (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id TEXT REFERENCES workout_templates(id) ON DELETE CASCADE,
  exercise_id TEXT REFERENCES exercises(id),
  order_index INTEGER,
  target_sets INTEGER,
  target_reps INTEGER,
  target_weight_kg NUMERIC(10,2)
);
```

---

### Offline Database (Flutter — SQLite via drift or sqflite)

**Current state:** Zero offline support. Any network drop = blank screens or error states. The only offline data is the exercise seed list.

**What to add in Phase 2:**

The app needs a local SQLite database that mirrors the server data and syncs when connectivity returns.

**Package:** Use `drift` (formerly Moor) — it's type-safe, works with Riverpod, and supports complex queries. Alternative is raw `sqflite` but drift gives you compile-time safety.

**What to cache locally:**

| Data | Cache strategy |
|------|---------------|
| Exercises | Sync on first load, cache permanently. These rarely change. |
| Workout sessions | Write locally first, sync to server in background. Show local data immediately. |
| Workout sets | Same as sessions — local-first. |
| Food catalog (searched/scanned items) | Cache individual items as user encounters them. Not the full catalog. |
| Food logs | Write locally first, sync in background. |
| User profile | Cache on login, refresh on app open. |
| Social feed posts | Cache last 50 posts. Serve from cache, refresh in background. |

**Sync architecture (keep it simple for solo dev):**

```
User action (add set, log food)
  → Write to local SQLite (immediate, no spinner)
  → Show success to user
  → Background: attempt API call
    → Success: mark local row as synced
    → Failure: keep in "pending sync" queue
  → On next app open: retry pending queue
```

Add a `sync_status` column to local-only tables: `pending | synced | failed`.

**What NOT to cache offline:**
- OTP auth (requires network by definition)
- Barcode lookups (need fresh data from OFD/Nutritionix)
- Social feed writes (a post with no network can wait)
- AI companion (requires API)

**Packages to add:**
```yaml
drift: ^2.18.0
drift_flutter: ^0.2.0          # Flutter-specific drift setup
connectivity_plus: ^5.0.2      # detect online/offline state
```

**Implementation order for offline:**
1. Local exercise cache first (easiest, read-only)
2. Local workout session/set writes (highest impact — users want to log mid-workout)
3. Local food log writes
4. Sync queue + retry logic
5. Social feed cache (lowest priority)

---

## What's NOT in scope yet (Phase 3+)
- AI companion
- M-Pesa / Stripe payments
- Spotify music suggestions
- Data import (Strong/Hevy/Apple Health)
- White-label build flavors


---

## Appendix: Food Feature Decision Log

**Date:** September 2024  
**Decision:** Shelve food/nutrition tracking indefinitely  
**Implemented:** Migration 008 (`008_drop_food.sql`) — dropped all food-related tables

### What was removed
- `foods` table — Open Food Facts catalog + custom foods
- `food_logs` table — daily food entries
- `nutrition_goals` table — user calorie/macro targets
- `water_logs` table — daily water intake
- `meal_plans` + related tables — meal planning feature
- User profile columns: `body_weight_kg`, `height_cm`, `age`, `activity_level`, `goal_type`

### Why it was shelved
1. **Scope creep** — Food tracking is complex (barcode scanning, nutrition APIs, meal planning) and would delay core workout/social features
2. **Market fit uncertainty** — Gyms are primarily interested in workout tracking and retention. Nutrition is secondary and gyms often have external nutrition coaches.
3. **API costs** — Quality nutrition data (Nutritionix, USDA) requires paid APIs. Open Food Facts has poor coverage for Kenyan/African foods.
4. **Maintenance burden** — Food databases require constant updates. User-generated content needs moderation.

### If it comes back
- Start simple: basic calorie/macro counter with manual entry only
- Partner with a nutrition API provider for African food coverage (or build a custom catalog)
- Consider making it a premium feature to offset API costs
- Build the Flutter UI separately and wire it to a new backend module

### Design artifacts preserved
- `Design Reference/stitch gympulse food and nutricion/` — UI mockups kept for reference
- Schema diagrams in `docs/archive/planning/`

**Do not remove this section** — it documents an important product decision and prevents future confusion about "missing" features referenced in early planning docs.
