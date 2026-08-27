# Phase 2 Plan — App Redesign + Social Layer
### Gym Companion | Dawn Digital

---

## Current State Audit

### What's working (Phase 1 backend ✅)
- Auth flow: OTP request/verify, staff login, roster matching — all wired up
- Workout sessions, sets, exercises — full CRUD in backend
- Food logs, food search, Open Food Facts proxy — backend complete
- Prisma migration run, all 9 Phase 1 tables live in Supabase
- Seed data: pilot gym, 32 exercises, 5 local Kenyan foods

### What's broken / incomplete right now
| Issue | Location | Impact |
|-------|----------|--------|
| `SKIP_LOGIN_FOR_TESTING = true` | `main.dart` | Fixed — now set to false. No token → 401 on all guarded routes |
| Token not persisted across app restarts | `ApiClient` | Token lives in memory only — killed when app closes |
| `deleteFoodLog()` throws `UnimplementedError` | `food_service.dart` | Delete button crashes |
| `updateFoodLog()` throws `UnimplementedError` | `food_service.dart` | No update endpoint on backend either |
| `WorkoutService.updateSession()` calls `PUT` | `workout_service.dart` | Backend uses `PATCH`, not `PUT` — will 404 |
| `WorkoutService.updateSet()` calls `PUT /workouts/sets/:id` | `workout_service.dart` | Endpoint doesn't exist on backend |
| `WorkoutService.deleteSession()` / `deleteSet()` | `workout_service.dart` | No DELETE endpoints on backend |
| All stats on Home + Profile screens are hardcoded `0` | `home_screen.dart`, `profile_screen.dart` | Placeholder UI only |
| `userId = 'user_id_placeholder'` | `food_screen.dart` | Auth state not wired to screens |
| No session persistence (logout = lose token) | `auth_service.dart` | User must re-OTP every cold start |
| No `social/` feature folder | mobile app | Phase 2 not started |
| No `ai_companion/` feature folder | mobile app | Phase 3, not started |
| No push notification setup | mobile + backend | Phase 2, not started |
| No `GymStaff` auth_provider_id index | Prisma schema | Minor — missing index on staff guard lookups |
| `foods` table missing `updatedAt` | Prisma schema | Inconsistent with other tables |
| No Row Level Security on Supabase | Supabase config | All tables publicly readable if someone hits DB directly |

---

## Database — What to Add and When

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
Add a 5th tab for Social (Phase 2). Consider renaming and reordering:
- Home → Feed (social) for engagement
- Move "Workouts" to tab 1 (it's the core feature)
- Keep Food, Profile

**Theme**
Current theme is generic Material 3. For a gym app targeting Nairobi users:
- Dark mode as default (gyms are dimly lit)
- High contrast accent color — the current indigo (`#4F46E5`) works; could go bolder
- Custom font (Google Fonts — Poppins or Inter) — no licensing cost, one line in pubspec
- Heavier use of cards with subtle gradients on key CTAs
- Gym logo/branding surfaced on home screen using the `primaryColor` field already in the DB

**Home Screen**
Currently all static. Should show:
- Greeting with user's actual display name (from auth state)
- Today's workout (if one exists) or a "Start Workout" CTA
- Calorie ring for today (vs a goal — even a hardcoded 2000 kcal goal for MVP)
- Recent post from their gym's feed (Phase 2 hook)
- Streak counter (requires `user_achievements` table)

**Profile Screen**
- Show real user data (name, email, gym name) from auth state
- Working logout (currently `// TODO`)
- Subscription tier badge
- Stats pulled from real DB queries (workout count, streak)

**Workouts Screen**
- Remove the history screen being embedded — give it its own tab treatment or a full sheet
- Make the "Start Workout" button more prominent

**Food Screen**
- Calorie progress bar at top (calories logged vs goal)
- Macro rings (protein/carbs/fat)
- Fix the broken delete/update calls

---

## Packages to Add

For Phase 2 redesign, add to `pubspec.yaml`:

```yaml
# Auth persistence
flutter_secure_storage: ^9.0.0   # store tokens securely

# Supabase (consider using SDK directly for real-time features)
supabase_flutter: ^2.3.0

# UI
google_fonts: ^6.1.0             # Poppins/Inter
cached_network_image: ^3.3.1     # gym logos, avatars, post images

# Camera / media
image_picker: ^1.0.7             # profile pic + post photos
mobile_scanner: ^4.0.1           # barcode scanning (replaces placeholder)

# Push notifications
firebase_core: ^2.27.1
firebase_messaging: ^14.7.20
flutter_local_notifications: ^17.0.0

# Connectivity
connectivity_plus: ^5.0.2        # offline detection

# Misc
intl: ^0.19.0                    # date formatting (already needed in food screen)
timeago: ^3.6.1                  # "2 hours ago" style timestamps for social feed
```

---

## Build Sequence (recommended order)

### Step 1 — Foundation fixes (do first, unblocks everything else)
1. Set up Supabase RLS policies + storage buckets
2. Add `push_tokens` + social tables to Prisma, run migration
3. Add `flutter_secure_storage` + wire up token persistence (store on login, load on startup)
4. Wire auth state to screens — create a proper `AuthState` provider with user context
5. Fix the broken endpoints: add DELETE for sessions/sets/food logs to backend
6. Fix `PUT` vs `PATCH` mismatch in workout service

### Step 2 — App redesign
7. Add Google Fonts, update theme (dark default, custom typography)
8. Redesign Home screen with real data (workout today, calorie ring, streak)
9. Fix Profile screen (real name/email, working logout, real stats)
10. Add barcode scanner to food flow (replaces the placeholder)
11. Add image picker to profile

### Step 3 — Phase 2 social
12. Build `social/` feature: posts, likes, comments
13. Build Social tab (gym-scoped feed)
14. Auto-post achievements (new PR, streak milestone)
15. Wire up push notifications (FCM setup + backend trigger)

### Step 4 — Admin portal
16. Build basic Next.js admin portal: member list, roster upload, pending approvals, feed moderation
17. This is the thing you need to show gym owners — build it before Phase 3

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
