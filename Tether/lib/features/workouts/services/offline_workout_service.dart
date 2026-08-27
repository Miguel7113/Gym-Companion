import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/exercises_dao.dart';
import '../../../core/database/daos/sessions_dao.dart';
import '../../../core/database/daos/templates_dao.dart';
import '../../../core/sync/sync_service.dart';
import '../models/workout_models.dart';
import 'workout_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OfflineWorkoutService
//
// The single service the UI talks to for all workout operations.
// Wraps WorkoutService (the pure API client) with local-first logic:
//
//   READ:  always hits local SQLite first — fast and offline-capable
//   WRITE: writes to SQLite first, then triggers background sync to server
//
// The UI never waits for a network response during a workout.
// ─────────────────────────────────────────────────────────────────────────────
class OfflineWorkoutService {
  final AppDatabase _db;
  final WorkoutService _api;
  final SyncService _sync;

  OfflineWorkoutService(this._db, this._api, this._sync);

  ExercisesDao get _exercises => _db.exercisesDao;
  SessionsDao get _sessions => _db.sessionsDao;
  TemplatesDao get _templates => _db.templatesDao;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  String get _currentGymId {
    final meta =
        Supabase.instance.client.auth.currentSession?.user.userMetadata ?? {};
    return (meta['gym_id'] as String?) ?? '';
  }

  // ── Exercises ─────────────────────────────────────────────────────────────

  /// Returns exercises from local cache. Falls back to API if cache is empty.
  /// Triggers a background cache refresh if stale (non-blocking).
  Future<List<Exercise>> listExercises({
    String? query,
    String? bodyPart,
    String? category,
    List<String>? equipment,
  }) async {
    final cacheCount = await _exercises.getCacheCount();

    // Cache is empty — fetch from API and populate cache before returning
    if (cacheCount == 0) {
      debugPrint('[OfflineWorkout] cache empty — fetching from API');
      try {
        final apiResults = await _api.listExercises(
          query: query,
          bodyPart: bodyPart,
          category: category,
          equipment: equipment?.isNotEmpty == true ? equipment!.first : null,
        );
        // Seed these results into cache for next time
        await _exercises.upsertAll(apiResults);
        return apiResults;
      } catch (e) {
        debugPrint('[OfflineWorkout] API fallback failed: $e');
        return [];
      }
    }

    // Cache has data — use it
    // Trigger background refresh if stale (doesn't block the return)
    _exercises.isCacheStale().then((stale) {
      if (stale) {
        debugPrint('[OfflineWorkout] cache stale — background refresh');
        _sync.seedIfNeeded();
      }
    });

    return _exercises.filterCombined(
      bodyPart: bodyPart,
      equipments: equipment,
      query: query,
      category: category,
    );
  }

  Future<List<String>> listBodyParts() async {
    final cacheCount = await _exercises.getCacheCount();
    if (cacheCount == 0) {
      // Fall back to API
      try {
        return await _api.listBodyParts();
      } catch (_) {
        return [];
      }
    }
    return _exercises.getDistinctBodyParts();
  }

  Future<List<String>> listEquipments() async {
    final cacheCount = await _exercises.getCacheCount();
    if (cacheCount == 0) {
      try {
        return await _api.listEquipments();
      } catch (_) {
        return [];
      }
    }
    return _exercises.getDistinctEquipments();
  }

  Future<Exercise?> getExercise(String id) async {
    // Try local cache first
    final cached = await _exercises.getById(id);
    if (cached != null) return cached;
    // Fall back to API
    try {
      return await _api.getExercise(id);
    } catch (_) {
      return null;
    }
  }

  // ── Recently Used ─────────────────────────────────────────────────────────

  Future<List<Exercise>> getRecentlyUsed({int limit = 10}) async {
    final userId = _currentUserId;
    if (userId.isEmpty) return [];
    return _exercises.getRecentlyUsed(userId, limit: limit);
  }

  Future<void> recordExerciseUsage(String exerciseId) async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;
    await _exercises.recordUsage(userId, exerciseId);
    // Fire and forget to server
    _api.saveExercise(exerciseId).catchError((_) {});
  }

  // ── Saved Exercises ───────────────────────────────────────────────────────

  Future<List<Exercise>> getSavedExercises() async {
    try {
      return await _api.getSavedExercises();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExercise(String id) => _api.saveExercise(id);
  Future<void> unsaveExercise(String id) => _api.unsaveExercise(id);

  // ── Templates ─────────────────────────────────────────────────────────────

  Future<List<WorkoutTemplate>> listTemplates() async {
    final cached = await _templates.getSystemAndGym();
    if (cached.isNotEmpty) return cached;
    // Cache empty — fetch from API
    try {
      final apiTemplates = await _api.getSavedPrograms();
      return apiTemplates;
    } catch (_) {
      return [];
    }
  }

  // ── Sessions (offline-first) ───────────────────────────────────────────────

  /// Creates a session locally — returns immediately, no network call.
  /// The returned WorkoutSession uses the local UUID as its ID until synced.
  Future<WorkoutSession> createSession({String? notes}) async {
    final gymId = _currentGymId;
    final userId = _currentUserId;

    if (gymId.isEmpty || userId.isEmpty) {
      throw Exception('Not authenticated — cannot create session');
    }

    final localId = await _sessions.createSession(
      gymId: gymId,
      userId: userId,
      notes: notes,
    );

    return WorkoutSession(
      id: localId,
      userId: userId,
      gymId: gymId,
      startedAt: DateTime.now(),
      notes: notes,
      sets: const [],
    );
  }

  /// Ends a session and triggers an immediate sync attempt if online.
  Future<WorkoutSession> endSession(String localId, {String? notes}) async {
    if (notes != null) {
      await _sessions.updateSessionNotes(localId, notes);
    }
    await _sessions.endSession(localId);

    // Non-blocking sync attempt — if offline this just logs and returns
    _sync.syncPendingSessions().catchError((e) {
      debugPrint('[OfflineWorkout] post-end sync failed: $e');
    });

    final row = await _sessions.getSessionByLocalId(localId);
    if (row == null) throw Exception('Session $localId not found');
    return _sessions.toWorkoutSession(row);
  }

  // Expose the DB directly so endSession can query it — no longer needed
  // (now uses sessionsDao.getSessionByLocalId)
  /// Adds a set to a session locally — returns immediately.
  /// Returns an AddSetResult with local IDs (no isPr until synced).
  Future<AddSetResult> addSet(
    String sessionId, {
    required String exerciseId,
    String? sessionServerId,
    int? setNumber,
    int? reps,
    double? weightKg,
    double? rpe,
    double? assistKg,
    int? durationSecs,
    double? distanceM,
    double? speedKph,
  }) async {
    final sessionLocalId =
        await _sessions.resolveLocalId(sessionId) ?? sessionId;
    final sessionRow = await _sessions.getSessionByLocalId(sessionLocalId);
    final serverId = sessionServerId ?? sessionRow?.serverId;

    final localSetId = await _sessions.addSet(
      sessionLocalId: sessionLocalId,
      exerciseId: exerciseId,
      sessionServerId: serverId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      rpe: rpe,
      assistKg: assistKg,
      durationSecs: durationSecs,
      distanceM: distanceM,
      speedKph: speedKph,
    );

    // Record exercise usage in recently_used_cache
    await _exercises
        .recordUsage(_currentUserId, exerciseId)
        .catchError((_) {});

    _sync.syncPendingSessions().catchError((e) {
      debugPrint('[OfflineWorkout] post-set sync failed: $e');
    });

    final set = WorkoutSet(
      id: localSetId,
      sessionId: sessionLocalId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      rpe: rpe,
      assistKg: assistKg,
      durationSecs: durationSecs,
      distanceM: distanceM,
      speedKph: speedKph,
    );

    return AddSetResult(set: set, isPr: false);
  }

  Future<void> deleteSet(String setId) async {
    await _sessions.deleteSet(setId);
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessions.deleteSession(sessionId);
  }

  // ── Session history ────────────────────────────────────────────────────────

  Future<List<WorkoutSession>> listSessions({int limit = 20}) async {
    final userId = _currentUserId;
    final rows = await _sessions.getHistory(userId, limit: limit);
    final result = <WorkoutSession>[];
    for (final r in rows) {
      result.add(_sessions.toWorkoutSession(r));
    }
    return result;
  }

  Future<WorkoutSession?> getActiveSession() async {
    final userId = _currentUserId;
    final row = await _sessions.getActiveSession(userId);
    if (row == null) return null;
    return _sessions.toWorkoutSession(row);
  }

  // ── Stats (for home screen) ────────────────────────────────────────────────

  Future<int> getSessionCountThisWeek() async {
    return _sessions.getSessionCountThisWeek(_currentUserId);
  }

  Future<int> getStreak() async {
    return _sessions.getStreak(_currentUserId);
  }

  Future<int> getTotalWorkoutCount() async {
    return _sessions.getTotalEndedSessionCount(_currentUserId);
  }

  Future<int> getSetsCountThisWeek() async {
    return _sessions.getSetsCountThisWeek(_currentUserId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────
final offlineWorkoutServiceProvider = Provider<OfflineWorkoutService>((ref) {
  return OfflineWorkoutService(
    ref.watch(appDatabaseProvider),
    ref.watch(workoutServiceProvider),
    ref.watch(syncServiceProvider),
  );
});
