import 'package:json_annotation/json_annotation.dart';

part 'workout_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exercise
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  final String? category;
  final List<String> bodyParts;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipments;
  final String? difficulty;
  final String? gifUrl;
  final List<String> instructions;
  final String? overview;
  final bool isCustom;
  final String? createdByUserId;

  const Exercise({
    required this.id,
    required this.name,
    this.category,
    this.bodyParts = const [],
    this.targetMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipments = const [],
    this.difficulty,
    this.gifUrl,
    this.instructions = const [],
    this.overview,
    this.isCustom = false,
    this.createdByUserId,
  });

  /// Whether this exercise uses loaded weight (barbell, dumbbell, cable, etc.)
  bool get isWeighted {
    const weightedEquipment = {
      'barbell', 'dumbbell', 'cable', 'kettlebell', 'weighted',
      'smith machine', 'leverage machine', 'ez barbell', 'trap bar',
    };
    return equipments.any((e) => weightedEquipment.contains(e.toLowerCase()));
  }

  /// Whether this is an assisted exercise (e.g. assisted pull-up machine)
  bool get isAssisted {
    return equipments.any((e) => e.toLowerCase() == 'assisted');
  }

  /// Whether this is purely bodyweight (no equipment or body weight only)
  bool get isBodyweight {
    return equipments.isEmpty ||
        (equipments.length == 1 && equipments.first.toLowerCase() == 'body weight');
  }

  /// Whether this is a cardio exercise
  bool get isCardio => category?.toLowerCase() == 'cardio';

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSet — one logged set, supports both strength and cardio
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class WorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int? setNumber;
  // Strength
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final double? assistKg;
  // Cardio
  final int? durationSecs;
  final double? distanceM;
  final double? speedKph;
  final Exercise? exercise;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    this.setNumber,
    this.reps,
    this.weightKg,
    this.rpe,
    this.assistKg,
    this.durationSecs,
    this.distanceM,
    this.speedKph,
    this.exercise,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => _$WorkoutSetFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSetToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// AddSetResult — { set, isPr } from POST /workouts/sessions/:id/sets
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class AddSetResult {
  final WorkoutSet set;
  final bool isPr;

  const AddSetResult({required this.set, required this.isPr});

  factory AddSetResult.fromJson(Map<String, dynamic> json) => _$AddSetResultFromJson(json);
  Map<String, dynamic> toJson() => _$AddSetResultToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSession
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class WorkoutSession {
  final String id;
  final String userId;
  final String gymId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final List<WorkoutSet> sets;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.sets = const [],
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSessionToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutTemplate — a program/template (system, gym, or user-created)
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class WorkoutTemplate {
  final String id;
  final String? gymId;
  final String name;
  final String? description;
  final String? category;
  final String? difficulty;
  final int? durationMins;
  // 'system' | 'gym' | 'user'
  final String source;
  final String? imageUrl;
  final bool isActive;
  final List<WorkoutTemplateExercise> exercises;

  const WorkoutTemplate({
    required this.id,
    this.gymId,
    required this.name,
    this.description,
    this.category,
    this.difficulty,
    this.durationMins,
    this.source = 'system',
    this.imageUrl,
    this.isActive = true,
    this.exercises = const [],
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => _$WorkoutTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutTemplateToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutTemplateExercise — one exercise entry within a template
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class WorkoutTemplateExercise {
  final String id;
  final String templateId;
  final String exerciseId;
  final int sortOrder;
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeightKg;
  final int? defaultDurationSecs;
  final double? defaultDistanceM;
  final String? notes;
  final Exercise? exercise;

  const WorkoutTemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.defaultSets,
    this.defaultReps,
    this.defaultWeightKg,
    this.defaultDurationSecs,
    this.defaultDistanceM,
    this.notes,
    this.exercise,
  });

  factory WorkoutTemplateExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutTemplateExerciseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// LocalWorkoutTemplate — hardcoded default programs living in Flutter only.
// No JSON serialization needed — these never come from the API.
// Converted to BuilderExerciseEntry list when user starts from a template.
// ─────────────────────────────────────────────────────────────────────────────
class LocalWorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMins;
  final String imageUrl;
  final List<LocalTemplateExercise> exercises;

  const LocalWorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMins,
    required this.imageUrl,
    required this.exercises,
  });
}

class LocalTemplateExercise {
  final String exerciseName; // matched to DB by name on load
  final int sets;
  final int? reps;
  final int? durationSecs;
  final String? notes;

  const LocalTemplateExercise({
    required this.exerciseName,
    required this.sets,
    this.reps,
    this.durationSecs,
    this.notes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BuilderSet — one planned set in the workout builder (pre-session)
// Not persisted until the user actually starts and logs the workout.
// ─────────────────────────────────────────────────────────────────────────────
class BuilderSet {
  // Strength
  final double? weightKg;
  final int? reps;
  final double? rpe;
  final double? assistKg;
  // Cardio
  final int? durationSecs;
  final double? distanceM;
  final double? speedKph;

  BuilderSet({
    this.weightKg,
    this.reps,
    this.rpe,
    this.assistKg,
    this.durationSecs,
    this.distanceM,
    this.speedKph,
  });

  BuilderSet copyWith({
    double? weightKg,
    int? reps,
    double? rpe,
    double? assistKg,
    int? durationSecs,
    double? distanceM,
    double? speedKph,
  }) {
    return BuilderSet(
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      assistKg: assistKg ?? this.assistKg,
      durationSecs: durationSecs ?? this.durationSecs,
      distanceM: distanceM ?? this.distanceM,
      speedKph: speedKph ?? this.speedKph,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BuilderExerciseEntry — one exercise in the workout builder list
// Holds the Exercise + its planned sets before logging begins
// ─────────────────────────────────────────────────────────────────────────────
class BuilderExerciseEntry {
  final String uid; // local unique key for Flutter widget tree
  final Exercise exercise;
  final List<BuilderSet> sets;
  final bool isExpanded;

  BuilderExerciseEntry({
    required this.uid,
    required this.exercise,
    List<BuilderSet>? sets,
    this.isExpanded = true,
  }) : sets = sets ?? [BuilderSet()];

  BuilderExerciseEntry copyWith({
    Exercise? exercise,
    List<BuilderSet>? sets,
    bool? isExpanded,
  }) {
    return BuilderExerciseEntry(
      uid: uid,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DTOs
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class CreateExerciseDto {
  final String name;
  final String? category;

  const CreateExerciseDto({required this.name, this.category});

  factory CreateExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateExerciseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateExerciseDtoToJson(this);
}

@JsonSerializable()
class CreateSessionDto {
  final String? notes;

  const CreateSessionDto({this.notes});

  factory CreateSessionDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSessionDtoToJson(this);
}

@JsonSerializable()
class UpdateSessionDto {
  final String? notes;
  final bool? ended;

  const UpdateSessionDto({this.notes, this.ended});

  factory UpdateSessionDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateSessionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateSessionDtoToJson(this);
}

@JsonSerializable()
class CreateSetDto {
  final String exerciseId;
  final int? setNumber;
  // Strength
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final double? assistKg;
  // Cardio
  final int? durationSecs;
  final double? distanceM;
  final double? speedKph;

  const CreateSetDto({
    required this.exerciseId,
    this.setNumber,
    this.reps,
    this.weightKg,
    this.rpe,
    this.assistKg,
    this.durationSecs,
    this.distanceM,
    this.speedKph,
  });

  factory CreateSetDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSetDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSetDtoToJson(this);
}

@JsonSerializable()
class ProgressData {
  final DateTime date;
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final int? durationSecs;
  final double? distanceM;
  final double? speedKph;

  const ProgressData({
    required this.date,
    this.reps,
    this.weightKg,
    this.rpe,
    this.durationSecs,
    this.distanceM,
    this.speedKph,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) =>
      _$ProgressDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressDataToJson(this);
}
