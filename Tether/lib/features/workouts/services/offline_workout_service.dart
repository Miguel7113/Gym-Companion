import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/exercises_dao.dart';
import '../../../core/database/daos/sessions_dao.dart';
import '../../../core/database/daos/templates_dao.dart';
import '../../../core/sync/connectivity_provider.dart';
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

  Future<int> _prepareExerciseCache() async {
    var count = await _exercises.getCacheCount();
    final seedComplete = await _sync.isExerciseSeedComplete();
    if (count == 0 || !seedComplete) {
      await _sync.seedIfNeeded();
      count = await _exercises.getCacheCount();
    }
    return count;
  }

  /// Returns exercises from local cache. Falls back to API if cache is empty.
  /// Triggers a background cache refresh if stale (non-blocking).
  Future<List<Exercise>> listExercises({
    String? query,
    String? bodyPart,
    String? category,
    List<String>? equipment,
  }) async {
    // Wait only when the cache is empty or known to be partial. A stale but
    // complete cache remains immediately usable while it refreshes in the
    // background below.
    final cacheCount = await _prepareExerciseCache();

    // If the seed was unavailable, use the filtered API as an online fallback.
    if (cacheCount == 0 && await checkIsOnline()) {
      debugPrint('[OfflineWorkout] seed unavailable — fetching from API');
      try {
        final apiResults = await _api.listExercises(
          query: query,
          bodyPart: bodyPart,
          category: category,
          // Fetch the unfiltered set when multiple equipment values are
          // selected, then apply the local OR filter below.
          equipment: equipment?.length == 1 ? equipment!.first : null,
        );
        // Seed these results into cache for next time
        await _exercises.upsertAll(apiResults);
        return _exercises.filterCombined(
          bodyPart: bodyPart,
          equipments: equipment,
          query: query,
          category: category,
        );
      } catch (e) {
        debugPrint('[OfflineWorkout] API fallback failed: $e');
        return [];
      }
    }

    if (cacheCount == 0) return [];

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
    final cachedParts = await _exercises.getDistinctBodyParts();
    if (cachedParts.isNotEmpty) {
      _refreshExerciseCacheInBackground();
      return cachedParts;
    }
    if (!await checkIsOnline()) return [];
    try {
      final parts = await _api.listBodyParts();
      _refreshExerciseCacheInBackground();
      return parts;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> listEquipments() async {
    final cachedEquipments = await _exercises.getDistinctEquipments();
    if (cachedEquipments.isNotEmpty) {
      _refreshExerciseCacheInBackground();
      return cachedEquipments;
    }
    if (!await checkIsOnline()) return [];
    try {
      final equipments = await _api.listEquipments();
      _refreshExerciseCacheInBackground();
      return equipments;
    } catch (_) {
      return [];
    }
  }

  void _refreshExerciseCacheInBackground() {
    _sync.seedIfNeeded().catchError((error) {
      debugPrint('[OfflineWorkout] background seed failed: $error');
    });
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
  Future<WorkoutSession> createSession({
    String? notes,
    String? templateId,
  }) async {
    final gymId = _currentGymId;
    final userId = _currentUserId;

    if (gymId.isEmpty || userId.isEmpty) {
      throw Exception('Not authenticated — cannot create session');
    }

    final localId = await _sessions.createSession(
      gymId: gymId,
      userId: userId,
      templateId: templateId,
      notes: notes,
    );

    return WorkoutSession(
      id: localId,
      userId: userId,
      gymId: gymId,
      templateId: templateId,
      startedAt: DateTime.now(),
      notes: notes,
      sets: const [],
    );
  }

  /// Ends a session and triggers an immediate sync attempt if online.
  Future<WorkoutSession> endSession(String localId, {String? notes}) async {
    final resolvedLocalId = await _sessions.resolveLocalId(localId) ?? localId;
    if (notes != null) {
      await _sessions.updateSessionNotes(resolvedLocalId, notes);
    }
    await _sessions.endSession(resolvedLocalId);

    // Push the completed session to the server when online so sharing can use
    // the server session id immediately afterward.
    if (await checkIsOnline()) {
      try {
        await _sync.syncPendingSessions();
      } catch (e) {
        debugPrint('[OfflineWorkout] post-end sync failed: $e');
      }
    }

    final row = await _sessions.getSessionByLocalId(resolvedLocalId);
    if (row == null) throw Exception('Session $localId not found');
    return _hydrateSession(row);
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
    await _exercises.recordUsage(_currentUserId, exerciseId).catchError((_) {});

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

  Future<String?> getServerSessionId(String sessionId) async {
    final localId = await _sessions.resolveLocalId(sessionId);
    if (localId == null) return null;
    final session = await _sessions.getSessionByLocalId(localId);
    return session?.serverId;
  }

  // ── Session history ────────────────────────────────────────────────────────

  Future<List<WorkoutSession>> listLocalSessions({int limit = 20}) async {
    final rows = await _sessions.getHistory(_currentUserId, limit: limit);
    return Future.wait(rows.map(_hydrateSession));
  }

  Future<WorkoutSession> _hydrateSession(PendingSession row) async {
    final setRows = await _sessions.getSetsForSession(row.localId);
    final sets = await Future.wait(
      setRows.map((setRow) async {
        final exercise = await _exercises.getById(setRow.exerciseId);
        return _sessions.toWorkoutSet(setRow, exercise);
      }),
    );
    return _sessions.toWorkoutSession(row, sets);
  }

  Future<List<WorkoutSession>> listSessions({int limit = 20}) async {
    final localSessions = await listLocalSessions(limit: limit);

    // Merge local + remote by id. Prefer whichever copy has more sets so a
    // freshly finished offline workout isn't replaced by an empty server stub.
    if (await checkIsOnline()) {
      try {
        final remoteSessions = (await _api.listSessions(
          limit: limit,
        )).where((session) => session.endedAt != null).toList();

        final byId = <String, WorkoutSession>{};
        for (final session in remoteSessions) {
          byId[session.id] = session;
        }
        for (final local in localSessions) {
          final existing = byId[local.id];
          if (existing == null ||
              local.sets.length > existing.sets.length) {
            byId[local.id] = local;
          }
        }

        final merged = byId.values.toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return merged.take(limit).toList();
      } catch (e) {
        debugPrint('[OfflineWorkout] remote history unavailable: $e');
      }
    }

    return localSessions;
  }

  Future<WorkoutSession?> getActiveSession() async {
    final userId = _currentUserId;
    final row = await _sessions.getActiveSession(userId);
    if (row == null) return null;
    return _hydrateSession(row);
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
