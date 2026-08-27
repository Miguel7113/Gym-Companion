# Flutter App Guide

## Project Structure

```
lib/
├── main.dart                          # Entry point, Supabase init
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Supabase URL, OTP config
│   ├── navigation/
│   │   └── main_navigation.dart       # Bottom nav shell
│   └── theme/
│       └── app_theme.dart             # Dark theme config
└── features/
    ├── auth/
    │   ├── models/
    │   │   └── auth_models.dart       # Gym, GymMember, AuthState (Freezed)
    │   ├── providers/
    │   │   └── auth_provider.dart     # Riverpod: AuthNotifier, selectedGym
    │   ├── services/
    │   │   └── auth_service.dart      # Supabase calls + Edge Functions
    │   └── screens/
    │       ├── gym_selection_screen.dart
    │       ├── otp_request_screen.dart
    │       └── otp_verification_screen.dart
    ├── workout/
    │   ├── models/
    │   ├── providers/
    │   ├── services/
    │   └── screens/
    ├── feed/
    │   ├── models/
    │   ├── providers/
    │   ├── services/
    │   └── screens/
    └── profile/
        └── screens/
            └── profile_screen.dart
```

## State Management

We use **Riverpod** with the following pattern:

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `supabaseClientProvider` | `Provider` | Global Supabase client instance |
| `authServiceProvider` | `Provider` | AuthService instance |
| `authStateStreamProvider` | `StreamProvider` | Reactive auth state (member loaded) |
| `selectedGymProvider` | `StateProvider` | Currently selected gym (before login) |
| `authNotifierProvider` | `StateNotifierProvider` | Auth actions (request/verify OTP, sign out) |

### Auth State Machine

```
[Unauthenticated]
      │
      ▼ (user selects gym)
[Gym Selected]
      │
      ▼ (user requests OTP)
[OTP Sent]
      │
      ▼ (user verifies OTP)
[Authenticated] ──▶ loads member profile ──▶ [MainNavigation]
      │
      ▼ (sign out)
[Unauthenticated]
```

## Auth Flow Implementation

### 1. Gym Selection

The first screen shows two ways to find a gym:

**By Code:** Exact match on `gyms.code` (e.g., `IRON2024`)
**By Name:** Partial search with `ilike` on `gyms.name`

When a gym is selected, it's stored in `selectedGymProvider`. The app then navigates to `OtpRequestScreen`.

### 2. OTP Request

The member chooses email or phone, enters their contact info, and taps "Send Code".

The `AuthNotifier.requestOtp()` method:
1. Reads `selectedGymProvider` for `gym_id`
2. Calls the `auth-request-otp` Edge Function
3. Edge Function validates:
   - Gym exists and subscription is active
   - Member is pre-registered (`gym_members` row exists)
   - Rate limit not exceeded (max 3 per 10 min)
4. If valid, Supabase sends OTP via Twilio/email
5. App navigates to `OtpVerificationScreen`

### 3. OTP Verification

Member enters the 6-digit code. The `AuthNotifier.verifyOtp()` method:
1. Calls the `auth-verify-otp` Edge Function
2. Edge Function:
   - Verifies OTP with Supabase Auth
   - Finds the pre-registered member
   - If first claim: links `auth_user_id` to `gym_members`
   - Updates JWT claims with `gym_id`, `member_id`, `role`
   - Refreshes session to get updated JWT
3. App persists session via `supabase.auth.setSession()`
4. `authStateStreamProvider` detects new session → loads member profile
5. App navigates to `MainNavigation`

### 4. Session Persistence

Supabase Flutter automatically persists the session to secure storage. On app restart:
1. `Supabase.initialize()` restores the session
2. `authStateStreamProvider` emits the restored session
3. If session is valid → `MainNavigation`
4. If expired → back to `GymSelectionScreen`

## Adding New Features

### Pattern: Feature-First Architecture

Each feature is self-contained:

```
features/workout/
├── models/           # Data classes (Freezed)
├── providers/        # Riverpod providers
├── services/         # API calls to Supabase
├── screens/          # UI screens
└── widgets/          # Reusable widgets within the feature
```

### Example: Adding a Workout History Screen

**1. Model**
```dart
@freezed
class WorkoutHistoryEntry with _$WorkoutHistoryEntry {
  const factory WorkoutHistoryEntry({
    required String id,
    required DateTime startedAt,
    DateTime? endedAt,
    required int exerciseCount,
    required int setCount,
    required bool prAchieved,
  }) = _WorkoutHistoryEntry;

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$WorkoutHistoryEntryFromJson(json);
}
```

**2. Service**
```dart
class WorkoutService {
  final SupabaseClient _client;
  WorkoutService(this._client);

  Future<List<WorkoutHistoryEntry>> getHistory(String memberId) async {
    final response = await _client
        .from('workout_sessions')
        .select('id, started_at, ended_at, pr_achieved, sets:workout_sets(count)')
        .eq('member_id', memberId)
        .order('started_at', ascending: false);

    return (response as List)
        .map((json) => WorkoutHistoryEntry.fromJson(json))
        .toList();
  }
}
```

**3. Provider**
```dart
final workoutServiceProvider = Provider((ref) =>
  WorkoutService(ref.read(supabaseClientProvider)));

final workoutHistoryProvider = FutureProvider.autoDispose
    .family<List<WorkoutHistoryEntry>, String>((ref, memberId) async {
  final service = ref.read(workoutServiceProvider);
  return service.getHistory(memberId);
});
```

**4. Screen**
```dart
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(authNotifierProvider).member?.id;
    final historyAsync = ref.watch(workoutHistoryProvider(memberId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        data: (entries) => ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) => WorkoutHistoryCard(
            entry: entries[index],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

## Realtime Subscriptions

Use Supabase Realtime for live feed updates:

```dart
final feedChannelProvider = Provider<RealtimeChannel>((ref) {
  final client = ref.read(supabaseClientProvider);
  final gymId = ref.watch(authNotifierProvider).member?.gymId;

  return client
      .channel('feed:$gymId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'feed_posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'gym_id',
          value: gymId,
        ),
        callback: (payload) {
          ref.read(feedPostsProvider.notifier).prependPost(payload.newRecord);
        },
      )
      .subscribe();
});
```

## Push Notifications

1. Add `firebase_messaging` to `pubspec.yaml`
2. Configure FCM for iOS/Android
3. On app launch, get FCM token and save to `push_tokens` table
4. Edge Function `push-notify` sends messages via FCM HTTP v1 API

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/auth_flow_test.dart
```

### Manual Testing Checklist
- [ ] Gym selection by code works
- [ ] Gym selection by name search works
- [ ] OTP request succeeds for pre-registered member
- [ ] OTP request fails for non-registered email
- [ ] OTP verification logs member in
- [ ] Session persists after app restart
- [ ] Sign out clears session and returns to gym selection
- [ ] RLS prevents cross-gym data access
