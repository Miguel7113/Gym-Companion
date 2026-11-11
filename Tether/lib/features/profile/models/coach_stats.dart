import 'package:json_annotation/json_annotation.dart';

part 'coach_stats.g.dart';

/// Statistics for a coach's PR verification dashboard
@JsonSerializable()
class CoachStats {
  /// Total number of pending PRs awaiting verification
  final int pendingCount;
  
  /// Number of PRs verified today (last 24 hours)
  final int verifiedToday;
  
  /// Average response time in hours
  final double avgResponseTimeHours;
  
  /// Breakdown by exercise type
  final ExerciseBreakdown byExercise;

  const CoachStats({
    required this.pendingCount,
    required this.verifiedToday,
    required this.avgResponseTimeHours,
    required this.byExercise,
  });

  factory CoachStats.fromJson(Map<String, dynamic> json) =>
      _$CoachStatsFromJson(json);
  
  Map<String, dynamic> toJson() => _$CoachStatsToJson(this);
}

/// Breakdown of pending PRs by exercise type
@JsonSerializable()
class ExerciseBreakdown {
  final int benchPress;
  final int squat;
  final int deadlift;

  const ExerciseBreakdown({
    this.benchPress = 0,
    this.squat = 0,
    this.deadlift = 0,
  });

  factory ExerciseBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ExerciseBreakdownFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExerciseBreakdownToJson(this);
}

/// Empty state for loading
const kEmptyCoachStats = CoachStats(
  pendingCount: 0,
  verifiedToday: 0,
  avgResponseTimeHours: 0,
  byExercise: ExerciseBreakdown(),
);
