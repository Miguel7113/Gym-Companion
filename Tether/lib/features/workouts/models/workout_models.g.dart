// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String?,
  bodyParts:
      (json['bodyParts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  targetMuscles:
      (json['targetMuscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  secondaryMuscles:
      (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  equipments:
      (json['equipments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  difficulty: json['difficulty'] as String?,
  gifUrl: json['gifUrl'] as String?,
  instructions:
      (json['instructions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  overview: json['overview'] as String?,
  isCustom: json['isCustom'] as bool? ?? false,
  createdByUserId: json['createdByUserId'] as String?,
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'bodyParts': instance.bodyParts,
  'targetMuscles': instance.targetMuscles,
  'secondaryMuscles': instance.secondaryMuscles,
  'equipments': instance.equipments,
  'difficulty': instance.difficulty,
  'gifUrl': instance.gifUrl,
  'instructions': instance.instructions,
  'overview': instance.overview,
  'isCustom': instance.isCustom,
  'createdByUserId': instance.createdByUserId,
};

WorkoutSet _$WorkoutSetFromJson(Map<String, dynamic> json) => WorkoutSet(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  exerciseId: json['exerciseId'] as String,
  setNumber: (json['setNumber'] as num?)?.toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  rpe: (json['rpe'] as num?)?.toDouble(),
  assistKg: (json['assistKg'] as num?)?.toDouble(),
  durationSecs: (json['durationSecs'] as num?)?.toInt(),
  distanceM: (json['distanceM'] as num?)?.toDouble(),
  speedKph: (json['speedKph'] as num?)?.toDouble(),
  exercise: json['exercise'] == null
      ? null
      : Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WorkoutSetToJson(WorkoutSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'exerciseId': instance.exerciseId,
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'rpe': instance.rpe,
      'assistKg': instance.assistKg,
      'durationSecs': instance.durationSecs,
      'distanceM': instance.distanceM,
      'speedKph': instance.speedKph,
      'exercise': instance.exercise,
    };

AddSetResult _$AddSetResultFromJson(Map<String, dynamic> json) => AddSetResult(
  set: WorkoutSet.fromJson(json['set'] as Map<String, dynamic>),
  isPr: json['isPr'] as bool,
);

Map<String, dynamic> _$AddSetResultToJson(AddSetResult instance) =>
    <String, dynamic>{'set': instance.set, 'isPr': instance.isPr};

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    WorkoutSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      gymId: json['gymId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      notes: json['notes'] as String?,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutSessionToJson(WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'gymId': instance.gymId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'notes': instance.notes,
      'sets': instance.sets,
    };

WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) =>
    WorkoutTemplate(
      id: json['id'] as String,
      gymId: json['gymId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      durationMins: (json['durationMins'] as num?)?.toInt(),
      source: json['source'] as String? ?? 'system',
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WorkoutTemplateExercise.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutTemplateToJson(WorkoutTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gymId': instance.gymId,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'durationMins': instance.durationMins,
      'source': instance.source,
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
      'exercises': instance.exercises,
    };

WorkoutTemplateExercise _$WorkoutTemplateExerciseFromJson(
  Map<String, dynamic> json,
) => WorkoutTemplateExercise(
  id: json['id'] as String,
  templateId: json['templateId'] as String,
  exerciseId: json['exerciseId'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  defaultSets: (json['defaultSets'] as num?)?.toInt(),
  defaultReps: (json['defaultReps'] as num?)?.toInt(),
  defaultWeightKg: (json['defaultWeightKg'] as num?)?.toDouble(),
  defaultDurationSecs: (json['defaultDurationSecs'] as num?)?.toInt(),
  defaultDistanceM: (json['defaultDistanceM'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  exercise: json['exercise'] == null
      ? null
      : Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WorkoutTemplateExerciseToJson(
  WorkoutTemplateExercise instance,
) => <String, dynamic>{
  'id': instance.id,
  'templateId': instance.templateId,
  'exerciseId': instance.exerciseId,
  'sortOrder': instance.sortOrder,
  'defaultSets': instance.defaultSets,
  'defaultReps': instance.defaultReps,
  'defaultWeightKg': instance.defaultWeightKg,
  'defaultDurationSecs': instance.defaultDurationSecs,
  'defaultDistanceM': instance.defaultDistanceM,
  'notes': instance.notes,
  'exercise': instance.exercise,
};

CreateExerciseDto _$CreateExerciseDtoFromJson(Map<String, dynamic> json) =>
    CreateExerciseDto(
      name: json['name'] as String,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$CreateExerciseDtoToJson(CreateExerciseDto instance) =>
    <String, dynamic>{'name': instance.name, 'category': instance.category};

CreateSessionDto _$CreateSessionDtoFromJson(Map<String, dynamic> json) =>
    CreateSessionDto(notes: json['notes'] as String?);

Map<String, dynamic> _$CreateSessionDtoToJson(CreateSessionDto instance) =>
    <String, dynamic>{'notes': instance.notes};

UpdateSessionDto _$UpdateSessionDtoFromJson(Map<String, dynamic> json) =>
    UpdateSessionDto(
      notes: json['notes'] as String?,
      ended: json['ended'] as bool?,
    );

Map<String, dynamic> _$UpdateSessionDtoToJson(UpdateSessionDto instance) =>
    <String, dynamic>{'notes': instance.notes, 'ended': instance.ended};

CreateSetDto _$CreateSetDtoFromJson(Map<String, dynamic> json) => CreateSetDto(
  exerciseId: json['exerciseId'] as String,
  setNumber: (json['setNumber'] as num?)?.toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  rpe: (json['rpe'] as num?)?.toDouble(),
  assistKg: (json['assistKg'] as num?)?.toDouble(),
  durationSecs: (json['durationSecs'] as num?)?.toInt(),
  distanceM: (json['distanceM'] as num?)?.toDouble(),
  speedKph: (json['speedKph'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CreateSetDtoToJson(CreateSetDto instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'rpe': instance.rpe,
      'assistKg': instance.assistKg,
      'durationSecs': instance.durationSecs,
      'distanceM': instance.distanceM,
      'speedKph': instance.speedKph,
    };

ProgressData _$ProgressDataFromJson(Map<String, dynamic> json) => ProgressData(
  date: DateTime.parse(json['date'] as String),
  reps: (json['reps'] as num?)?.toInt(),
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  rpe: (json['rpe'] as num?)?.toDouble(),
  durationSecs: (json['durationSecs'] as num?)?.toInt(),
  distanceM: (json['distanceM'] as num?)?.toDouble(),
  speedKph: (json['speedKph'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProgressDataToJson(ProgressData instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'rpe': instance.rpe,
      'durationSecs': instance.durationSecs,
      'distanceM': instance.distanceM,
      'speedKph': instance.speedKph,
    };
