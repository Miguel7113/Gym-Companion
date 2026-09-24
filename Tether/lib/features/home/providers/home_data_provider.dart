import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/services/social_service.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/services/offline_workout_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeData — everything the home screen needs in one object.
// Food/nutrition fields removed — feature shelved.
// ─────────────────────────────────────────────────────────────────────────────
class HomeData {
  /// The in-progress session for today (startedAt == today, endedAt == null).
  final WorkoutSession? activeSession;

  /// Number of completed sessions today.
  final int todayWorkoutCount;

  /// Consecutive days the user has logged at least one completed workout.
  final int streakDays;

  /// Most recent achievement post preview for social teaser.
  final SocialPostPreview? latestAchievementPost;

  /// Members with sessions today — used in social teaser copy.
  final int activeTodayCount;

  const HomeData({
    this.activeSession,
    required this.todayWorkoutCount,
    required this.streakDays,
    this.latestAchievementPost,
    required this.activeTodayCount,
  });

  HomeData copyWith({
    WorkoutSession? activeSession,
    int? todayWorkoutCount,
    int? streakDays,
    SocialPostPreview? latestAchievementPost,
    int? activeTodayCount,
  }) {
    return HomeData(
      activeSession: activeSession ?? this.activeSession,
      todayWorkoutCount: todayWorkoutCount ?? this.todayWorkoutCount,
      streakDays: streakDays ?? this.streakDays,
      latestAchievementPost:
          latestAchievementPost ?? this.latestAchievementPost,
      activeTodayCount: activeTodayCount ?? this.activeTodayCount,
    );
  }

  static const empty = HomeData(
    activeSession: null,
    todayWorkoutCount: 0,
    streakDays: 0,
    latestAchievementPost: null,
    activeTodayCount: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SocialPostPreview — minimal shape for the social teaser card.
// ─────────────────────────────────────────────────────────────────────────────
class SocialPostPreview {
  final String authorName;
  final bool authorIsStaff;
  final String caption;
  final String? achievementTag;
  final String timeAgo;

  const SocialPostPreview({
    required this.authorName,
    required this.authorIsStaff,
    required this.caption,
    this.achievementTag,
    required this.timeAgo,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeDataNotifier
// ─────────────────────────────────────────────────────────────────────────────
class HomeDataNotifier extends AutoDisposeAsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() => _fetch();

  Future<HomeData> _fetch() async {
    ref.watch(authStateStreamProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return HomeData.empty;

    final offline = ref.read(offlineWorkoutServiceProvider);
    final today = _todayDate();

    final activeSession = await offline.getActiveSession();
    final streakDays = await offline.getStreak();
    final history = await offline.listLocalSessions(limit: 30);
    SocialPostPreview? latestAchievementPost;
    final todayCount = history
        .where((s) => s.endedAt != null && _isSameDay(s.startedAt, today))
        .length;

    try {
      final feed = await ref.read(socialServiceProvider).getFeed(limit: 1);
      if (feed.isNotEmpty) {
        final latest = feed.first;
        latestAchievementPost = SocialPostPreview(
          authorName: latest.authorName,
          authorIsStaff: latest.authorIsStaff,
          caption: latest.content,
          achievementTag: latest.achievementType,
          timeAgo: _timeAgo(latest.createdAt),
        );
      }
    } catch (_) {
      // Home remains usable even if the social teaser cannot load.
    }

    return HomeData(
      activeSession:
          activeSession != null &&
              activeSession.endedAt == null &&
              _isSameDay(activeSession.startedAt, today)
          ? activeSession
          : null,
      todayWorkoutCount: todayCount,
      streakDays: streakDays,
      latestAchievementPost: latestAchievementPost,
      activeTodayCount: 0,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  DateTime _todayDate([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

final homeDataProvider =
    AsyncNotifierProvider.autoDispose<HomeDataNotifier, HomeData>(
      HomeDataNotifier.new,
    );
