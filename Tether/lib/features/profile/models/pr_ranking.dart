import 'package:json_annotation/json_annotation.dart';

part 'pr_ranking.g.dart';

/// Represents a single user's ranking for a specific exercise
/// Used in profile showcase to display podium positions
@JsonSerializable()
class PRRanking {
  final int rank; // 0 = not ranked, 1 = first place, 2 = second, etc.
  final String userId;
  final String displayName;
  final String? avatarPath;
  final String? gender;
  final double prValue; // Calculated PR value (e.g., Wilks score, or raw weight)
  final double? weightKg;
  final int reps;
  final DateTime achievedDate;
  final bool isCurrentUser;

  PRRanking({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarPath,
    this.gender,
    required this.prValue,
    this.weightKg,
    required this.reps,
    required this.achievedDate,
    this.isCurrentUser = false,
  });

  /// Returns true if this user has a verified PR (is on the leaderboard)
  bool get isRanked => rank > 0;

  /// Returns true if this is a podium position (top 3)
  bool get isPodium => rank > 0 && rank <= 3;

  /// Returns medal emoji for podium positions
  String? get medalEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  /// Display text for the PR value (e.g., "120kg x 5 reps")
  String get displayText {
    final weight = weightKg != null ? '${weightKg!.toStringAsFixed(1)}kg' : '';
    final repsText = reps > 0 ? ' x $reps ${reps == 1 ? 'rep' : 'reps'}' : '';
    return weight.isNotEmpty ? '$weight$repsText' : 'No PR';
  }

  /// Display text for rank (e.g., "1st", "2nd", "Not Ranked #15")
  String get rankText {
    if (!isRanked) {
      return 'Not Ranked';
    }
    switch (rank) {
      case 1:
        return '1st Place';
      case 2:
        return '2nd Place';
      case 3:
        return '3rd Place';
      default:
        return '#$rank';
    }
  }

  factory PRRanking.fromJson(Map<String, dynamic> json) =>
      _$PRRankingFromJson(json);

  Map<String, dynamic> toJson() => _$PRRankingToJson(this);

  /// Creates a "not ranked" placeholder for a user
  factory PRRanking.notRanked({
    required String userId,
    required String displayName,
    String? avatarPath,
    String? gender,
  }) {
    return PRRanking(
      rank: 0,
      userId: userId,
      displayName: displayName,
      avatarPath: avatarPath,
      gender: gender,
      prValue: 0,
      weightKg: null,
      reps: 0,
      achievedDate: DateTime.now(),
      isCurrentUser: true,
    );
  }

  PRRanking copyWith({
    int? rank,
    String? userId,
    String? displayName,
    String? avatarPath,
    String? gender,
    double? prValue,
    double? weightKg,
    int? reps,
    DateTime? achievedDate,
    bool? isCurrentUser,
  }) {
    return PRRanking(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      gender: gender ?? this.gender,
      prValue: prValue ?? this.prValue,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      achievedDate: achievedDate ?? this.achievedDate,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

/// Represents a complete leaderboard for one exercise
/// Includes top 3 podium + current user's position
@JsonSerializable()
class PRLeaderboard {
  final String exerciseName; // 'Bench Press', 'Squat', or 'Deadlift'
  final List<PRRanking> topThree; // Podium positions (may be < 3 if not enough PRs)
  final PRRanking? currentUserRanking; // Null if user has no verified PR
  final int totalRanked; // Total number of users with verified PRs
  final String? genderFilter; // 'male', 'female', or null for 'all'

  PRLeaderboard({
    required this.exerciseName,
    required this.topThree,
    this.currentUserRanking,
    required this.totalRanked,
    this.genderFilter,
  });

  /// Returns true if current user is in the top 3
  bool get isUserOnPodium =>
      currentUserRanking != null && currentUserRanking!.isPodium;

  /// Returns true if current user has a verified PR for this exercise
  bool get isUserRanked =>
      currentUserRanking != null && currentUserRanking!.isRanked;

  /// Display text for total ranked users (e.g., "15 ranked members")
  String get totalRankedText {
    if (totalRanked == 0) return 'No rankings yet';
    if (totalRanked == 1) return '1 ranked member';
    return '$totalRanked ranked members';
  }

  /// Short exercise name for display (e.g., "Bench" instead of "Bench Press")
  String get shortName {
    switch (exerciseName.toLowerCase()) {
      case 'bench press':
        return 'Bench';
      case 'squat':
        return 'Squat';
      case 'deadlift':
        return 'Deadlift';
      default:
        return exerciseName;
    }
  }

  factory PRLeaderboard.fromJson(Map<String, dynamic> json) =>
      _$PRLeaderboardFromJson(json);

  Map<String, dynamic> toJson() => _$PRLeaderboardToJson(this);

  /// Creates an empty leaderboard (no PRs yet)
  factory PRLeaderboard.empty({
    required String exerciseName,
    String? genderFilter,
  }) {
    return PRLeaderboard(
      exerciseName: exerciseName,
      topThree: [],
      currentUserRanking: null,
      totalRanked: 0,
      genderFilter: genderFilter,
    );
  }
}

/// Aggregated response containing leaderboards for all 3 main exercises
/// This is what the profile showcase widget will consume
@JsonSerializable()
class PRShowcaseData {
  final PRLeaderboard benchPress;
  final PRLeaderboard squat;
  final PRLeaderboard deadlift;
  final DateTime fetchedAt;

  PRShowcaseData({
    required this.benchPress,
    required this.squat,
    required this.deadlift,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Returns all leaderboards as a list for iteration
  List<PRLeaderboard> get allLeaderboards => [benchPress, squat, deadlift];

  /// Returns true if the user is ranked in at least one exercise
  bool get hasAnyRanking {
    return benchPress.isUserRanked ||
        squat.isUserRanked ||
        deadlift.isUserRanked;
  }

  /// Returns number of podium positions the user has
  int get podiumCount {
    int count = 0;
    if (benchPress.isUserOnPodium) count++;
    if (squat.isUserOnPodium) count++;
    if (deadlift.isUserOnPodium) count++;
    return count;
  }

  factory PRShowcaseData.fromJson(Map<String, dynamic> json) =>
      _$PRShowcaseDataFromJson(json);

  Map<String, dynamic> toJson() => _$PRShowcaseDataToJson(this);

  /// Creates an empty showcase (no PRs for any exercise)
  factory PRShowcaseData.empty() {
    return PRShowcaseData(
      benchPress: PRLeaderboard.empty(exerciseName: 'Bench Press'),
      squat: PRLeaderboard.empty(exerciseName: 'Squat'),
      deadlift: PRLeaderboard.empty(exerciseName: 'Deadlift'),
    );
  }
}
