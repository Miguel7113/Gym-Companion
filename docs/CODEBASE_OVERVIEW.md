# Pulse — Codebase Overview

## Project Summary

Pulse is a multi-tenant gym management and social platform. Each gym is an isolated tenant. Members log in via OTP (email or SMS), track workouts, interact on a social feed, and receive gym notices. Gym staff manage members, content, and settings via a web dashboard (planned).

---

## Repository Structure

```
Gym-Companion/
├── gym_app_mobile/          # Flutter mobile app (iOS, Android, Linux desktop)
├── gym-app-backend/         # NestJS REST API + Supabase integration
├── gym-saas-starter-kit/    # Reference architecture (auth patterns, RLS, Edge Functions)
├── docs/                    # This documentation
└── Design Reference/        # Stitch design mockups for all screens
```

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Mobile | Flutter | 3.x |
| State Management | Riverpod | ^2.4.9 |
| Backend API | NestJS | 10.x |
| Database | PostgreSQL (via Supabase) | 15 |
| ORM | Prisma | 5.22 |
| Auth | Supabase Auth + OTP | 2.x |
| Realtime | Supabase (planned) | — |
| Storage | Supabase Storage (planned) | — |
| Admin Portal | Next.js 14 (planned) | — |

---

## Architecture

```
Flutter App
    │
    ├── auth endpoints ──────────────► NestJS /auth/*
    │                                       │
    ├── workout/social/feed ─────────► NestJS (all other routes)
    │                                       │
    └── gym list, Supabase session ──► Supabase directly
                                            │
                                    PostgreSQL DB
                                    (Supabase hosted)
```

**Key architectural decision:** Flutter talks to NestJS for all business logic (workouts, sessions, social posts). Flutter talks to Supabase directly only for:
1. Fetching the gym list (public read, no auth needed)
2. Persisting the Supabase session (via `supabase.auth.setSession()`)

NestJS uses the Supabase service role key (never exposed to clients) for all database operations via Prisma.

---

## Mobile App (`gym_app_mobile/`)

### Directory Structure

```
lib/
├── main.dart                        # App entry, Supabase.initialize(), _AuthGate
├── core/
│   ├── api_client.dart              # Dio HTTP client (talks to NestJS :3000)
│   ├── config/
│   │   └── supabase_config.dart     # Supabase URL + publishable key
│   ├── navigation/
│   │   └── main_navigation.dart     # 4-tab bottom nav (HOME/TRAIN/FEED/PROFILE)
│   ├── providers/
│   │   ├── api_provider.dart        # ApiClient Riverpod provider
│   │   └── nav_provider.dart        # navIndexProvider + NavTab constants
│   ├── theme/
│   │   └── app_theme.dart           # Dark theme, neon lime (#C3F400), typography
│   └── widgets/
│       └── glass_card.dart          # GlassCard, PrimaryButton, SecondaryButton,
│                                    # MetricChip, SkeletonBox, ConnectErrorState
├── features/
│   ├── auth/
│   │   ├── models/auth_models.dart  # User (from JWT), Gym, DTOs
│   │   ├── providers/auth_provider.dart  # authStateStreamProvider, currentUserProvider
│   │   ├── services/auth_service.dart    # getGyms(), requestOtp(), verifyOtp(), signOut()
│   │   └── screens/
│   │       ├── gym_selection_screen.dart
│   │       ├── otp_request_screen.dart
│   │       └── otp_verification_screen.dart
│   ├── home/
│   │   ├── providers/home_data_provider.dart  # HomeData, HomeDataNotifier
│   │   └── screens/home_screen.dart           # Hero, stats bento, notices, social teaser
│   ├── workouts/
│   │   ├── models/workout_models.dart         # Exercise, WorkoutSet, WorkoutSession, etc.
│   │   ├── services/workout_service.dart      # All workout API calls
│   │   ├── data/
│   │   │   ├── default_programs.dart          # 6 local workout templates
│   │   │   └── exercise_seed_data.dart        # Fallback exercises (offline)
│   │   └── screens/
│   │       ├── workouts_screen.dart           # Train tab (muscle grid, programs)
│   │       ├── workout_builder_screen.dart    # Pre-session exercise planner
│   │       ├── workout_session_screen.dart    # Live session (timer, sets, rest timer, PR)
│   │       ├── exercise_picker_sheet.dart     # Bottom sheet: search, filter, browse
│   │       ├── exercise_detail_screen.dart    # GIF, muscles, instructions, add CTA
│   │       ├── exercise_list_screen.dart      # Search results list
│   │       ├── workout_history_screen.dart    # Past sessions list
│   │       └── progress_screen.dart          # fl_chart progress graph
│   ├── social/
│   │   ├── models/feed_models.dart            # FeedPost, FeedComment
│   │   ├── providers/feed_provider.dart       # FeedNotifier (optimistic like, flag)
│   │   ├── services/social_service.dart       # getFeed, toggleLike, flag, comments
│   │   └── screens/social_screen.dart         # Feed tab
│   │   └── widgets/
│   │       ├── comments_sheet.dart            # Bottom sheet: flat comment list
│   │       └── create_post_sheet.dart         # Staff announcement compose
│   ├── notices/
│   │   └── screens/notices_screen.dart        # Full gym notices list + detail view
│   └── profile/
│       └── screens/profile_screen.dart        # User profile, sign out
```

### Navigation

4-tab `IndexedStack` bottom nav. Tab constants in `NavTab`:

```dart
NavTab.home    = 0  // HomeScreen
NavTab.train   = 1  // WorkoutsScreen
NavTab.feed    = 2  // SocialScreen
NavTab.profile = 3  // ProfileScreen
```

Deep linking between tabs via `ref.read(navIndexProvider.notifier).state = NavTab.train`.

### Auth Flow

```
App launch
    │
    ▼
Supabase.initialize() restores persisted session
    │
    ▼
authStateStreamProvider emits AuthState
    │
    ├── session == null  →  GymSelectionScreen
    └── session != null  →  MainNavigation
            │
            GymSelectionScreen
            │  queries Supabase directly: gyms table (is_active = true)
            │  stores selected gym in selectedGymProvider
            │
            OtpRequestScreen
            │  calls NestJS POST /auth/request-otp
            │  NestJS checks gym_roster, sends OTP via Supabase
            │
            OtpVerificationScreen
            │  calls NestJS POST /auth/verify-otp
            │  NestJS verifies OTP, creates users row, injects JWT claims
            │  returns { accessToken, refreshToken }
            │  Flutter calls supabase.auth.setSession(refreshToken)
            │  authStateStreamProvider emits new session
            │
            MainNavigation (auto-navigated by stream)
```

### State Management Pattern

All state uses Riverpod. Pattern:

```dart
// Provider types used
Provider<T>                 // Synchronous, no disposal
StateProvider<T>            // Simple mutable state (nav index, selected gym)
AsyncNotifierProvider<T>    // Async with loading/error/data states (HomeData, Feed)
StreamProvider<T>           // Reactive streams (auth state)
```

### Design System

All design tokens in `AppTheme`:
- **Primary accent:** `#C3F400` (neon lime) — the ONE brand colour
- **Surface hierarchy:** 6 levels from `surfaceContainerLowest` (#0D0E12) to `surfaceBright` (#38393D)
- **Typography:** Oswald (display/headers), Inter (body), JetBrains Mono (labels/monospace)
- **Spacing:** 8px base unit — `stackSm:12`, `gutter:16`, `stackMd:24`, `containerMargin:20`, `stackLg:40`
- **Radius:** `radiusSm:4`, `radiusLg:8`, `radiusXl:12`, `radiusXxl:16`, `radiusFull:9999`

---

## Backend (`gym-app-backend/`)

### Directory Structure

```
src/
├── main.ts                     # Bootstrap, port 3000
├── app.module.ts               # Module registry
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts      # POST /auth/request-otp, verify-otp, staff/login
│   ├── auth.service.ts         # OTP flow, JWT claim injection, session refresh
│   ├── supabase-auth.guard.ts  # Validates Supabase JWTs via JWT_SECRET
│   ├── staff-auth.guard.ts     # Staff-only routes
│   └── decorators/
│       ├── current-user.decorator.ts   # @CurrentMember() → { userId, gymId, isStaff }
│       └── public.decorator.ts         # @Public() → skip auth guard
├── workouts/
│   ├── workouts.module.ts
│   ├── workouts.controller.ts  # /exercises, /workouts/sessions, /workouts/sets
│   ├── workouts.service.ts     # Exercise library, sessions, sets, PR detection
│   └── dto/workouts.dto.ts
├── social/
│   ├── social.module.ts
│   ├── social.controller.ts    # /social/posts, likes, flags, comments
│   └── social.service.ts       # Feed, createAchievementPost (called on PR)
├── roster/
│   ├── roster.module.ts
│   ├── roster.controller.ts    # /roster/import-csv, entry, pending, approve
│   └── roster.service.ts       # findRosterMatch, markMatched, createPending
├── gyms/
│   └── gyms.controller.ts      # /gyms (public), /gyms/:id/stats (staff)
├── food/                       # Shelved — code remains but food tab removed from nav
│   └── ...
├── prisma/
│   └── prisma.service.ts       # PrismaClient singleton
└── supabase/
    └── supabase.service.ts     # sendEmailOtp, verifyOtp, updateUserMetadata,
                                # refreshSession, createStaffUser
```

### Database

NestJS uses **local PostgreSQL** (`localhost:5433`) via Prisma for development. Production connects to Supabase via the pooler URL.

**Key tables in use:**

| Table | Purpose |
|---|---|
| `gyms` | Tenant records |
| `gym_roster` | Pre-registered members (status: unmatched → matched) |
| `gym_staff` | Staff accounts for admin portal |
| `users` | Claimed member profiles (created on first OTP login) |
| `exercises` | 873 seeded exercises from free-exercise-db |
| `workout_sessions` | Logged workout instances |
| `workout_sets` | Individual sets with strength + cardio fields |
| `user_achievements` | PR badges |
| `posts` | Social feed (achievement auto-posts + staff announcements) |
| `post_likes` | Likes |
| `post_comments` | Comments |
| `post_flags` | Moderation queue |

### Auth Guard

`SupabaseAuthGuard` validates every protected request:
1. Extracts `Bearer` token from `Authorization` header
2. Verifies with `SUPABASE_JWT_SECRET`
3. Looks up `users` row by `authProviderId`
4. Also checks `gym_staff` table to attach `isStaff` + `staffRole`
5. Sets `request.member = { userId, gymId, isStaff, staffRole }`

Routes marked `@Public()` skip the guard entirely.

### Supabase Migrations

All migrations in `supabase/migrations/` and applied to Supabase:

| Migration | Contents |
|---|---|
| `001` | Initial schema (from first build) |
| `002` | Workout module expansion (Exercise fields, Phase 2 tables) |
| `003` | Workout builder (meal_plan tables — shelved but present) |
| `004` | Social post_flags |
| `005` | Nutrition goals/water (shelved but tables exist) |
| `006` | Meal plans (shelved but tables exist) |
| `007` | DROP food/nutrition/meal plan tables |
| `008` | RLS policies for all tables |

### Supabase Edge Functions

Deployed to Supabase project `uqswohwqdcjlncdudhap`:

**`auth-request-otp`**
- Validates gym is active
- Checks `gym_roster` for pre-registration
- Creates `unmatched` roster entry if not found (pending approval flow)
- Calls `supabase.auth.signInWithOtp()`

**`auth-verify-otp`**
- Verifies OTP
- Finds/creates `users` row
- Links `gym_roster.matched_user_id`
- Injects `gym_id`, `member_id`, `role` into JWT via `admin.updateUserById`
- Refreshes session → returns `{ accessToken, refreshToken }`

---

## Current Status

### Working
- Flutter app builds and runs on Linux desktop and web
- 4-tab navigation (HOME / TRAIN / FEED / PROFILE)
- Home screen: hero photo, stats bento, gym notices, social teaser, trainer tip
- Train tab: muscle-group grid (873 exercises), programs row, exercise picker
- Workout builder: plan exercises before starting, strength/cardio set rows
- Active session screen: elapsed timer, set tables, rest timer, PR badge, FINISH flow
- Exercise detail: GIF, instructions, muscles, ADD TO WORKOUT
- Social feed: placeholder posts, optimistic like, flag with moderation
- Gym notices: list + detail view
- Auth screens: GymSelectionScreen, OtpRequestScreen, OtpVerificationScreen (UI complete)
- Supabase initialized in Flutter (`supabase_flutter ^2.5.6`)
- NestJS backend: all routes working, auth guard validates Supabase JWTs
- JWT claim injection on OTP verify (gym_id, member_id, role in JWT)
- RLS policies applied to all tables

### In Progress
- OTP email mode: Supabase sending magic link instead of 6-digit code (needs dashboard config)

### Not Yet Started
- Supabase Realtime feed subscriptions
- Push notifications (FCM)
- Profile screen data (edit display name, avatar)
- Classes/schedule feature
- Admin portal (Next.js)
- Production deployment

---

## Environment Variables

### Backend (`.env`)

```
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/gym_companion
SUPABASE_URL=https://uqswohwqdcjlncdudhap.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sb_secret_...     # Never expose to clients
SUPABASE_JWT_SECRET=<uuid>                  # From Supabase Project Settings → API → JWT
PORT=3000
```

### Flutter (build-time `--dart-define`)

```
SUPABASE_URL=https://uqswohwqdcjlncdudhap.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_... # Safe for client apps
```

---

## Development Commands

```bash
# Backend
cd gym-app-backend
npm run start:dev          # Start with hot reload
npm run build              # TypeScript compile check
npm run prisma:generate    # Regenerate Prisma client after schema change
npm run prisma:migrate     # Run pending migrations (local DB)
npm run seed:exercises     # Seed 873 exercises from free-exercise-db
npm run seed:meal-plans    # Seed 4 preset meal plans

# Flutter
cd gym_app_mobile
flutter run                # Run on connected device
flutter analyze lib/       # Static analysis
dart run build_runner build --delete-conflicting-outputs  # Codegen (json_serializable)
```
