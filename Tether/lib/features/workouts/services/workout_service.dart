import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/workout_models.dart';

class WorkoutService {
  final ApiClient _apiClient;
  WorkoutService(this._apiClient);

  // ─── Exercises ─────────────────────────────────────────────────────────────

  Future<List<Exercise>> listExercises({
    String? query,
    String? bodyPart,
    String? category,
    String? equipment,
  }) async {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (bodyPart != null && bodyPart.isNotEmpty) params['bodyPart'] = bodyPart;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (equipment != null && equipment.isNotEmpty) params['equipment'] = equipment;

    final response = await _apiClient.get('/exercises', queryParameters: params);
    return (response.data as List)
        .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Exercise> getExercise(String exerciseId) async {
    final response = await _apiClient.get('/exercises/$exerciseId');
    return Exercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> listBodyParts() async {
    final response = await _apiClient.get('/exercises/body-parts');
    return (response.data as List).cast<String>();
  }

  Future<List<String>> listEquipments() async {
    final response = await _apiClient.get('/exercises/equipments');
    return (response.data as List).cast<String>();
  }

  Future<Exercise> createExercise(CreateExerciseDto dto) async {
    final response = await _apiClient.post('/exercises', data: dto.toJson());
    return Exercise.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Saved Exercises ───────────────────────────────────────────────────────

  Future<List<Exercise>> getSavedExercises() async {
    final response = await _apiClient.get('/workouts/saved/exercises');
    return (response.data as List)
        .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExercise(String exerciseId) async {
    await _apiClient.post('/workouts/saved/exercises/$exerciseId');
  }

  Future<void> unsaveExercise(String exerciseId) async {
    await _apiClient.delete('/workouts/saved/exercises/$exerciseId');
  }

  // ─── Saved Programs ────────────────────────────────────────────────────────

  Future<List<WorkoutTemplate>> getSavedPrograms() async {
    final response = await _apiClient.get('/workouts/saved/programs');
    return (response.data as List)
        .map((j) => WorkoutTemplate.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProgram(String templateId) async {
    await _apiClient.post('/workouts/saved/programs/$templateId');
  }

  Future<void> unsaveProgram(String templateId) async {
    await _apiClient.delete('/workouts/saved/programs/$templateId');
  }

  // ─── Personal routines ────────────────────────────────────────────────────

  Future<List<WorkoutTemplate>> listRoutines() async {
    final response = await _apiClient.get('/workouts/routines');
    return (response.data as List)
        .map((j) => WorkoutTemplate.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutTemplate> createRoutine({
    required String name,
    required List<WorkoutTemplateExercise> exercises,
    String? description,
    String? category,
    String? difficulty,
    int? durationMins,
    bool isShared = false,
  }) async {
    final response = await _apiClient.post(
      '/workouts/routines',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
        if (durationMins != null) 'durationMins': durationMins,
        'isShared': isShared,
        'exercises': exercises.map((exercise) => {
          'exerciseId': exercise.exerciseId,
          'sortOrder': exercise.sortOrder,
          if (exercise.defaultSets != null)
            'defaultSets': exercise.defaultSets,
          if (exercise.defaultReps != null)
            'defaultReps': exercise.defaultReps,
          if (exercise.defaultWeightKg != null)
            'defaultWeightKg': exercise.defaultWeightKg,
          if (exercise.defaultDurationSecs != null)
            'defaultDurationSecs': exercise.defaultDurationSecs,
          if (exercise.defaultDistanceM != null)
            'defaultDistanceM': exercise.defaultDistanceM,
          if (exercise.notes != null) 'notes': exercise.notes,
        }).toList(),
      },
    );
    return WorkoutTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkoutTemplate> copyRoutine(String routineId) async {
    final response = await _apiClient.post('/workouts/routines/$routineId/copy');
    return WorkoutTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkoutTemplate> getRoutine(String routineId) async {
    final response = await _apiClient.get('/workouts/routines/$routineId');
    return WorkoutTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<WorkoutSession>> getRoutineHistory(String routineId) async {
    final response = await _apiClient.get(
      '/workouts/routines/$routineId/history',
    );
    return (response.data as List)
        .map((json) => WorkoutSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RoutineLeaderboard> getRoutineLeaderboard({
    required String routineId,
    required String exerciseId,
    String metric = 'volume',
  }) async {
    final response = await _apiClient.get(
      '/workouts/routines/$routineId/leaderboard',
      queryParameters: {'exerciseId': exerciseId, 'metric': metric},
    );
    return RoutineLeaderboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRoutine(String routineId) async {
    await _apiClient.delete('/workouts/routines/$routineId');
  }

  Future<List<WorkoutTemplate>> listGymPrograms({String? coachUserId}) async {
    final response = await _apiClient.get(
      '/workouts/programs',
      queryParameters: {
        if (coachUserId != null && coachUserId.isNotEmpty)
          'coachUserId': coachUserId,
      },
    );
    return (response.data as List)
        .map((j) => WorkoutTemplate.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutTemplate> publishRoutine(String routineId) async {
    final response =
        await _apiClient.post('/workouts/routines/$routineId/publish');
    return WorkoutTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkoutTemplate> unpublishRoutine(String routineId) async {
    final response =
        await _apiClient.post('/workouts/routines/$routineId/unpublish');
    return WorkoutTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkoutSession> createBuddySession({
    required String buddyUserId,
    String? templateId,
  }) async {
    final response = await _apiClient.post(
      '/workouts/sessions/buddy',
      data: {
        'buddyUserId': buddyUserId,
        if (templateId != null) 'templateId': templateId,
      },
    );
    return WorkoutSession.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Recently Used ─────────────────────────────────────────────────────────

  Future<List<Exercise>> getRecentlyUsed({int limit = 10}) async {
    final response = await _apiClient.get(
      '/workouts/recently-used',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ─── Sessions ──────────────────────────────────────────────────────────────

  Future<WorkoutSession> createSession(CreateSessionDto dto) async {
    final response = await _apiClient.post('/workouts/sessions', data: dto.toJson());
    return WorkoutSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkoutSession> updateSession(String sessionId, UpdateSessionDto dto) async {
    final response = await _apiClient.patch(
      '/workouts/sessions/$sessionId',
      data: dto.toJson(),
    );
    return WorkoutSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String sessionId) async {
    await _apiClient.delete('/workouts/sessions/$sessionId');
  }

  Future<List<WorkoutSession>> listSessions({int limit = 20, int offset = 0}) async {
    final response = await _apiClient.get(
      '/workouts/sessions',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (response.data as List)
        .map((j) => WorkoutSession.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ─── Sets ──────────────────────────────────────────────────────────────────

  Future<AddSetResult> addSet(String sessionId, CreateSetDto dto) async {
    final response = await _apiClient.post(
      '/workouts/sessions/$sessionId/sets',
      data: dto.toJson(),
    );
    return AddSetResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSet(String setId) async {
    await _apiClient.delete('/workouts/sets/$setId');
  }

  // ─── Progress ──────────────────────────────────────────────────────────────

  Future<List<ProgressData>> getProgress(String exerciseId) async {
    final response = await _apiClient.get('/workouts/progress/$exerciseId');
    return (response.data as List)
        .map((j) => ProgressData.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService(ref.watch(apiClientProvider));
});
