import '../../social/models/feed_models.dart';
import '../../workouts/models/workout_models.dart';

class MemberProfileStats {
  final int workoutCount;
  final int totalSets;
  final double totalVolume;
  final int streakDays;

  const MemberProfileStats({
    required this.workoutCount,
    required this.totalSets,
    required this.totalVolume,
    required this.streakDays,
  });

  factory MemberProfileStats.fromJson(Map<String, dynamic> json) {
    return MemberProfileStats(
      workoutCount: (json['workoutCount'] as num?)?.toInt() ?? 0,
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class MemberProfile {
  final String memberId;
  final String displayName;
  final String? avatarUrl;
  final String? staffRole;
  final String gymName;
  final bool isOwnProfile;
  final MemberProfileStats stats;
  final List<FeedPost> posts;
  final bool postsHasMore;
  final List<WorkoutTemplate> sharedRoutines;

  const MemberProfile({
    required this.memberId,
    required this.displayName,
    this.avatarUrl,
    this.staffRole,
    required this.gymName,
    required this.isOwnProfile,
    required this.stats,
    required this.posts,
    required this.postsHasMore,
    required this.sharedRoutines,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    final gym = (json['gym'] as Map?)?.cast<String, dynamic>() ?? {};
    return MemberProfile(
      memberId: json['memberId'] as String,
      displayName: json['displayName'] as String? ?? 'Gym member',
      avatarUrl: json['avatarUrl'] as String?,
      staffRole: json['staffRole'] as String?,
      gymName: gym['name'] as String? ?? 'Your gym',
      isOwnProfile: json['isOwnProfile'] as bool? ?? false,
      stats: MemberProfileStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      posts: (json['posts'] as List<dynamic>? ?? [])
          .map((post) => FeedPost.fromJson(post as Map<String, dynamic>))
          .toList(),
      postsHasMore: json['postsHasMore'] as bool? ?? false,
      sharedRoutines: (json['sharedRoutines'] as List<dynamic>? ?? [])
          .map(
            (routine) =>
                WorkoutTemplate.fromJson(routine as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
