# Tether — Offline Support Implementation Plan

> Status: PLANNED  
> Last updated: 2026-07-22  
> Author: Kiro

---

## 1. Overview

Tether members use the app inside a gym. Gyms often have poor or congested wifi.
The workout logging feature — the core daily loop — must never fail because of
a network issue. A member mid-set should never see "check your connection".

The strategy is **offline-first with background sync**:
- The app always reads from a local SQLite database (instant, no network)
- Writes go to SQLite first, then sync to NestJS when online
- The user never waits for the network during a workout

---

## 2. What Works Offline vs Online-Only

| Feature | Offline Support | Notes |
|---|---|---|
| Browse exercises | ✅ Full | Cached from server at login |
| Exercise picker filters | ✅ Full | Derived from cached exercises |
| Workout builder | ✅ Full | Local only until sync |
| Active workout / log sets | ✅ Full | Writes to SQLite immediately |
| Workout history (read) | ✅ Cached | Shows last known sessions |
| Workout templates / programs | ✅ Full | Cached at login |
| Recently used exercises | ✅ Cached | Local tracking |
| Home stats (streak, sessions this week) | ✅ Cached | Calculated from local sessions |
| Social feed | ❌ Online only | Needs real-time context |
| Auth / login | ❌ Online only | Session required |
| Profile edits | ❌ Online only | Low-frequency, not critical |
| Gym notices | ❌ Online only | Content-managed |

---

## 3. Technology Stack

### Local Database: Drift (SQLite)

`drift` (formerly Moor) is the correct choice over alternatives:

- **vs `shared_preferences`**: key-value only, not queryable, can't store
  relational data like sessions → sets
- **vs `hive`**: schemaless, no SQL queries, harder to migrate
- **vs `sqflite` raw**: no type safety, manual queries, no migrations
- **vs `isar`**: good but less mature Flutter ecosystem integration

Drift gives us:
- Type-safe table definitions in Dart
- Full SQL query support when needed
- Automatic migrations between schema versions
- Same code-generation pattern already used in the project
  (`json_serializable` → `drift_dev`)
- Works independently of Supabase — two separate persistence layers

### Connectivity Detection: `connectivity_plus`

Standard Flutter package for detecting network state changes. Used to:
- Show offline indicator in workout screens
- Trigger sync when connection is restored

### Background Sync: `workmanager`

Runs a sync task even when the app is in the background or closed.
Ensures sessions recorded in the gym sync to the server before the
member checks their history on the web portal.

---

## 4. New Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Local database (offline-first)
  drift: ^2.14.0
  drift_flutter: ^0.1.0

  # Network state detection
  connectivity_plus: ^6.0.3

  # Background sync (runs when app is backgrounded)
  workmanager: ^0.5.2

dev_dependencies:
  # Drift code generation
  drift_dev: ^2.14.0
```

`drift_flutter` provides the Flutter-specific database connection bindings
(uses `sqlite3_flutter_libs` under the hood — no manual native setup needed).

---

## 5. Local Database Schema

File: `lib/core/database/app_database.dart`

### Table: `exercises_cache`

Stores all 873 exercises fetched from the server. Queried locally for the
exercise picker instead of hitting the API every time.

```
Column          Type      Notes
─────────────────────────────────────────────────────
id              TEXT PK   Server UUID
name            TEXT      Exercise name
category        TEXT      'strength' | 'cardio' | 'hiit' | 'mobility'
body_parts      TEXT      JSON-encoded List<String>
target_muscles  TEXT      JSON-encoded List<String>
secondary_muscles TEXT    JSON-encoded List<String>
equipments      TEXT      JSON-encoded List<String>
difficulty      TEXT      'beginner' | 'intermediate' | 'advanced'
gif_url         TEXT      CDN URL for demo image
image_urls      TEXT      JSON-encoded { small, medium, large }
instructions    TEXT      JSON-encoded List<String>
overview        TEXT      Short description
is_custom       INTEGER   0 = system, 1 = user-created
cached_at       INTEGER   Unix ms — used to decide when to refresh
```

Indexes: `name`, `category`, `body_parts` (for filter queries).

### Table: `workout_templates_cache`

Stores system + gym templates. Loaded on the Train screen without a
network call.

```
Column          Type      Notes
─────────────────────────────────────────────────────
id              TEXT PK   Server UUID
name            TEXT
description     TEXT
category        TEXT
difficulty      TEXT
duration_mins   INTEGER
source          TEXT      'system' | 'gym' | 'user'
image_url       TEXT
exercises_json  TEXT      Full JSON blob of WorkoutTemplateExercise[]
                          (includes exercise names for display)
is_active       INTEGER
cached_at       INTEGER
```

### Table: `pending_sessions`

Workout sessions created offline or not yet confirmed synced to the server.

```
Column          Type      Notes
─────────────────────────────────────────────────────
local_id        TEXT PK   UUID generated locally (never changes)
server_id       TEXT      Server UUID — null until synced
gym_id          TEXT      From JWT claims at time of creation
user_id         TEXT      From JWT claims at time of creation
started_at      INTEGER   Unix ms
ended_at        INTEGER   Unix ms — null if session still active
notes           TEXT
sync_status     TEXT      'pending' | 'syncing' | 'synced' | 'failed'
sync_error      TEXT      Last error message if failed — for debugging
retry_count     INTEGER   How many sync attempts have been made
created_at      INTEGER   Unix ms
```

Indexes: `sync_status`, `user_id`.

### Table: `pending_sets`

Individual sets logged during a workout. Each set is synced independently
after its session has a server ID.

```
Column              Type    Notes
─────────────────────────────────────────────────────
local_id            TEXT PK UUID generated locally
server_id           TEXT    Server UUID — null until synced
session_local_id    TEXT FK → pending_sessions.local_id
session_server_id   TEXT    Populated when session syncs
exercise_id         TEXT    Server exercise UUID (always available — exercises cached)
set_number          INTEGER
reps                INTEGER
weight_kg           REAL
rpe                 REAL
assist_kg           REAL
duration_secs       INTEGER
distance_m          REAL
speed_kph           REAL
is_pr               INTEGER 0 | 1 — set by server during sync
sync_status         TEXT    'pending' | 'synced' | 'failed'
created_at          INTEGER Unix ms
```

Indexes: `session_local_id`, `sync_status`.

### Table: `recently_used_cache`

Locally tracked recently used exercises. Mirrors the server table but
works offline.

```
Column          Type      Notes
─────────────────────────────────────────────────────
id              TEXT PK   Same as exercise_id (one row per exercise)
exercise_id     TEXT
user_id         TEXT
used_at         INTEGER   Unix ms — updated on each use
use_count       INTEGER
```

---

## 6. Data Access Objects (DAOs)

File: `lib/core/database/daos/exercises_dao.dart`

```dart
// Key methods:
Future<List<ExerciseCacheEntry>> getAll()
Future<List<ExerciseCacheEntry>> search(String query)
Future<List<ExerciseCacheEntry>> filterByBodyPart(String bodyPart)
Future<List<ExerciseCacheEntry>> filterByEquipment(List<String> equipment)
Future<List<String>> getDistinctBodyParts()
Future<List<String>> getDistinctEquipments()
Future<void> upsertAll(List<ExerciseCacheEntry> exercises)
Future<bool> isCacheStale()  // true if cachedAt > 7 days ago
Future<void> clear()
```

File: `lib/core/database/daos/sessions_dao.dart`

```dart
// Key methods:
Future<String> createSession(PendingSession session)  // returns local_id
Future<void> updateSession(String localId, {DateTime? endedAt, String? notes})
Future<void> updateSyncStatus(String localId, String status, {String? serverId})
Future<List<PendingSession>> getPendingSessions()     // sync_status = 'pending'
Future<List<PendingSession>> getSessionHistory(String userId, {int limit})
Future<PendingSession?> getActiveSession(String userId)
Future<String> addSet(PendingSet set)                 // returns local_id
Future<void> markSetSynced(String localId, String serverId)
Future<List<PendingSet>> getPendingSetsForSession(String sessionLocalId)
```

File: `lib/core/database/daos/templates_dao.dart`

```dart
// Key methods:
Future<List<WorkoutTemplateCacheEntry>> getAll()
Future<List<WorkoutTemplateCacheEntry>> getBySource(String source)
Future<void> upsertAll(List<WorkoutTemplateCacheEntry> templates)
Future<bool> isCacheStale()
```

---

## 7. Offline Workout Service

File: `lib/features/workouts/services/offline_workout_service.dart`

This is the **single service the UI talks to**. It wraps the existing
`WorkoutService` (which becomes the pure online API client) and adds
local-first logic.

```
OfflineWorkoutService
  ├── ExercisesDAO      ← always reads locally
  ├── SessionsDAO       ← writes locally first
  ├── WorkoutService    ← called for sync only, never for reads during a session
  └── ConnectivityService
```

### Key method behaviours:

**`listExercises()`**
1. Read from `exercises_cache` immediately → return to UI
2. If online and cache is stale → trigger background refresh (don't block)
3. If cache is empty → fall back to API (first launch before seed completes)

**`listBodyParts()` / `listEquipments()`**
- Read from `exercises_cache` using DISTINCT queries on the JSON columns
- Zero network calls

**`createSession()`**
1. Generate a local UUID
2. Write to `pending_sessions` with `sync_status: 'pending'`
3. Return a `WorkoutSession` with the local ID immediately — no network
4. `SyncService` will handle server creation in background

**`addSet()`**
1. Write to `pending_sets` with `session_local_id` — immediate
2. Return `AddSetResult` with local IDs
3. If `session.server_id` is available → optionally sync immediately

**`endSession()`**
1. Update `pending_sessions.ended_at` locally
2. Trigger `SyncService.syncNow()` — non-blocking

**`listSessions()` (history)**
1. Read from `pending_sessions` where `user_id = currentUser`
2. Return all, regardless of sync_status

---

## 8. Sync Service

File: `lib/core/sync/sync_service.dart`

The sync service runs on two triggers:
- **Foreground**: when connectivity is restored (via `connectivity_plus` stream)
- **Background**: via `workmanager` periodic task (every 15 minutes)

### Sync Algorithm

```
syncPendingSessions():
  1. Get all pending_sessions where sync_status IN ('pending', 'failed')
     AND retry_count < 3
  2. For each session:
     a. Set sync_status = 'syncing'
     b. POST /workouts/sessions to NestJS
        → on success: update server_id, sync_status = 'syncing_sets'
        → on failure: sync_status = 'failed', retry_count++, log error
     c. Get all pending_sets for this session
     d. For each set:
        POST /workouts/sessions/:server_id/sets
        → on success: update set.server_id, set.sync_status = 'synced'
        → on failure: log, continue to next set
     e. If all sets synced: session.sync_status = 'synced'
     f. If some sets failed: session.sync_status = 'partial'

syncExerciseCache():
  1. Check exercises_dao.isCacheStale()
  2. If stale: fetch all from /exercises, upsert to exercises_cache
  3. Mark cache fresh (update cached_at on all rows)
```

### Connectivity Provider

```dart
// lib/core/sync/connectivity_provider.dart

// Riverpod stream provider — UI watches this
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
});

// When it changes from false → true, trigger syncNow()
```

### Sync Status Provider

```dart
// UI reads this to show "X workouts pending sync" badge
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  // Watches pending_sessions table via drift stream query
  return ref.watch(appDatabaseProvider)
    .sessionsDao
    .watchPendingCount()
    .map((count) => SyncStatus(pendingCount: count));
});
```

---

## 9. Background Sync with Workmanager

Registered in `main.dart` at app startup. Runs every 15 minutes even when
the app is backgrounded.

```dart
// Registration (in main()):
Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
Workmanager().registerPeriodicTask(
  'tether-sync',
  'syncPendingWorkouts',
  frequency: const Duration(minutes: 15),
  constraints: Constraints(networkType: NetworkType.connected),
);

// Top-level callback (must be a top-level function, not a method):
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'syncPendingWorkouts') {
      final db = AppDatabase();
      final apiClient = ApiClient();
      await SyncService(db, apiClient).syncPendingSessions();
    }
    return true;
  });
}
```

---

## 10. Exercise Seeding

### Backend seed script: `npm run seed:templates`

Creates 6 system workout templates in `workout_templates` table.
References exercises by their seeded IDs.

**Push Day** (category: strength, difficulty: intermediate)
- Bench Press — 4×8
- Incline Dumbbell Press — 3×10
- Overhead Press — 3×8
- Tricep Pushdown — 3×12
- Lateral Raise — 3×15

**Pull Day** (category: strength, difficulty: intermediate)
- Deadlift — 4×5
- Barbell Row — 4×8
- Pull-ups — 3×8
- Face Pull — 3×15
- Barbell Curl — 3×10

**Leg Day** (category: strength, difficulty: intermediate)
- Squat — 4×8
- Romanian Deadlift — 3×10
- Leg Press — 3×12
- Leg Curl — 3×12
- Calf Raise — 4×15

**Full Body** (category: strength, difficulty: beginner)
- Squat — 3×8
- Bench Press — 3×8
- Barbell Row — 3×8
- Overhead Press — 3×8
- Romanian Deadlift — 3×10

**Cardio Burn** (category: cardio, difficulty: beginner)
- Running — 1×30min
- Cycling — 1×20min
- Jump Rope — 3×5min

**Core & Mobility** (category: mobility, difficulty: beginner)
- Plank — 3×60sec
- Hanging Leg Raise — 3×12
- Crunches — 3×20

### Flutter first-login seed

After a successful login, `SyncService.seedExercisesIfNeeded()` is called once:

```
1. Check exercises_cache row count
2. If 0 → fetch all from GET /exercises (returns up to 873)
   — done in batches of 100 to avoid one massive response
3. Upsert all into exercises_cache
4. Fetch templates from GET /workouts/templates
5. Upsert all into workout_templates_cache
6. Write seed timestamp to shared_preferences
```

This runs silently in the background. The UI shows exercises from cache
immediately (empty on very first launch until seed completes — handled
with a loading state).

Cache refresh: triggered on app open if `cached_at` of any exercise is
older than 7 days. Runs in background, never blocks UI.

---

## 11. UI Changes

### `WorkoutBuilderScreen`

- `_startWorkout()` calls `offlineWorkoutService.createSession()` instead
  of `workoutService.createSession()`
- No try/catch for network errors — local write can't fail
- Show offline badge in app bar if `connectivityProvider` is false

### `ExercisePickerSheet`

- `_loadMeta()` calls `offlineWorkoutService.listBodyParts()` etc.
- These now read from SQLite — no timeout possible
- Remove the independent try/catch workaround added earlier

### `WorkoutSessionScreen`

- `addSet()` calls `offlineWorkoutService.addSet()`
- Writes locally, returns immediately
- Show small sync indicator icon (wifi_off) when offline

### `HomeScreen` stats

- Session count / streak read from `pending_sessions` local DB
- No network dependency for these numbers

### Global sync badge (optional, Phase 2)

- Small dot on the profile tab icon when `syncStatusProvider.pendingCount > 0`
- Tapping it shows sync status: "3 workouts waiting to sync"

---

## 12. File Structure After Implementation

```
lib/
  core/
    database/
      app_database.dart          ← Drift DB + table definitions
      app_database.g.dart        ← generated
      daos/
        exercises_dao.dart
        sessions_dao.dart
        templates_dao.dart
        recently_used_dao.dart
    sync/
      sync_service.dart
      connectivity_provider.dart
  features/
    workouts/
      services/
        workout_service.dart          ← unchanged (pure API client)
        offline_workout_service.dart  ← new (local-first wrapper)
      providers/
        workout_providers.dart        ← updated to use offline service
```

---

## 13. Implementation Order

Do these in sequence — each step is independently testable.

### Phase 1: Local database foundation
1. Add packages to `pubspec.yaml`
2. Create `app_database.dart` — table definitions only, no DAOs yet
3. Run `build_runner` — verify generated files compile
4. Create `exercises_dao.dart` with upsert + query methods
5. Create `sessions_dao.dart` with create + list methods
6. Initialize DB in `main.dart`

### Phase 2: Exercise cache
7. Add `SyncService.seedExercisesIfNeeded()` — fetches from API, writes to cache
8. Call it after successful login in `_AuthGate`
9. Update `ExercisePickerSheet` to read from `exercises_dao` first
10. Verify exercise picker works without network

### Phase 3: Offline workout logging
11. Create `offline_workout_service.dart`
12. Update `workout_builder_screen.dart` to use it
13. Update `workout_session_screen.dart` to use it
14. Add connectivity indicator to workout screens

### Phase 4: Background sync
15. Create `sync_service.dart` sync loop
16. Create `connectivity_provider.dart` — trigger sync on reconnect
17. Register `workmanager` background task
18. Test: log a workout offline, go online, verify it appears on server

### Phase 5: Backend templates seed
19. Create `prisma/seed-templates.ts`
20. Add `seed:templates` script to `package.json`
21. Run seed on Supabase
22. Update Flutter template cache to pull from backend instead of `default_programs.dart`

---

## 14. Error States and Edge Cases

| Scenario | Handling |
|---|---|
| App opened for first time, never been online | Exercise picker shows loading until seed completes. If no connection, shows "Connect to internet to load exercises" with retry button |
| Workout logged offline, session never syncs (3 retries exhausted) | Session stays in local DB with `sync_status: 'failed'`. User can manually trigger retry from workout history screen. Never deleted — data is preserved. |
| Server rejects a set during sync (validation error) | Set marked `sync_status: 'failed'`, session marked `sync_status: 'partial'`. Other sets in same session still sync. |
| User logs out with pending syncs | Warn: "You have unsynced workouts. Log out anyway?" — pending sessions are tagged with user_id so they survive session clear and can sync on next login. |
| Two sessions active simultaneously (e.g. force-quit mid-workout and reopen) | `getActiveSession()` checks for session with no `ended_at`. If found, offers to resume or discard. |
| Exercise cache corrupted | `clear()` then re-seed. Show "Refreshing exercises..." toast. |
| DB migration (schema change in future update) | Drift handles via `MigrationStrategy` — increment `schemaVersion`, provide step migrations. |

---

## 15. What This Unlocks Later

Once offline-first is in place, these features become much easier:
- **PR detection** — compare new set against local history without an API call
- **Workout streak** — calculate from local sessions, always accurate
- **Rest timer** — purely local, doesn't need a server
- **Volume tracking** — sum sets from local DB per muscle group per week
- **Workout suggestions** — "you haven't trained legs in 5 days" from local data
