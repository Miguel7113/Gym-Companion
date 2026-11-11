// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoachStats _$CoachStatsFromJson(Map<String, dynamic> json) => CoachStats(
  pendingCount: (json['pendingCount'] as num).toInt(),
  verifiedToday: (json['verifiedToday'] as num).toInt(),
  avgResponseTimeHours: (json['avgResponseTimeHours'] as num).toDouble(),
  byExercise: ExerciseBreakdown.fromJson(
    json['byExercise'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CoachStatsToJson(CoachStats instance) =>
    <String, dynamic>{
      'pendingCount': instance.pendingCount,
      'verifiedToday': instance.verifiedToday,
      'avgResponseTimeHours': instance.avgResponseTimeHours,
      'byExercise': instance.byExercise,
    };

ExerciseBreakdown _$ExerciseBreakdownFromJson(Map<String, dynamic> json) =>
    ExerciseBreakdown(
      benchPress: (json['benchPress'] as num?)?.toInt() ?? 0,
      squat: (json['squat'] as num?)?.toInt() ?? 0,
      deadlift: (json['deadlift'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ExerciseBreakdownToJson(ExerciseBreakdown instance) =>
    <String, dynamic>{
      'benchPress': instance.benchPress,
      'squat': instance.squat,
      'deadlift': instance.deadlift,
    };
