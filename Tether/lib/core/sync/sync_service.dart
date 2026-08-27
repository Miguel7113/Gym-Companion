import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_client.dart';
import '../database/app_database.dart';
import '../database/daos/exercises_dao.dart';
import '../database/daos/sessions_dao.dart';
import '../database/daos/templates_dao.dart';
import '../providers/api_provider.dart';
import 'connectivity_provider.dart';
import '../../features/workouts/models/workout_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SyncService
//
// Orchestrates all data synchronisation between the local SQLite database
// and the NestJS backend.
//
// Two responsibilities:
//  1. SEED   — populate the local cache from the server on first login
//  2. SYNC   — push pending sessions/sets to the server when online
//
// Called from:
//  - main.dart after login (seed)
//  - connectivity stream when going online (sync)
//  - workmanager background task every 15 min (sync)
// ─────────────────────────────────────────────────────────────────────────────
class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;

  SyncService(this._db, this._apiClient);

  ExercisesDao get _exercisesDao => _db.exercisesDao;
  SessionsDao get _sessionsDao => _db.sessionsDao;
  TemplatesDao get _templatesDao => _db.templatesDao;

  static const _seedDoneKey = 'exercise_cache_seeded_v1';
  static const _batchSize = 100;
  static const _maxSeedPages = 20;

  // ── Seed ──────────────────────────────────────────────────────────────────

  /// Fetches all exercises and templates from the server and writes them to
  /// the local cache. Safe to call multiple times — skips if already seeded
  /// and cache is fresh.
  ///
  /// Pass [force] = true to re-seed even if cache is fresh (e.g. after a
  /// manual "refresh" button tap).
  Future<void> seedIfNeeded({bool force = false}) async {
    final isOnline = await checkIsOnline();
    if (!isOnline) {
      debugPrint('[SyncService] offline — skipping seed');
      return;
    }

    // Check if we need to seed exercises
    final cacheStale = await _exercisesDao.isCacheStale();
    if (!force && !cacheStale) {
      debugPrint('[SyncService] exercise cache is fresh — skipping seed');
      await _seedTemplatesIfNeeded(force: false);
      return;
    }

    debugPrint('[SyncService] seeding exercise cache...');
    await _seedExercises();
    await _seedTemplatesIfNeeded(force: force);
  }

  Future<void> _seedExercises() async {
    try {
      // Fetch in batches to avoid one enormous response
      int offset = 0;
      final allExercises = <Exercise>[];
      var page = 0;

      while (page < _maxSeedPages) {
        final response = await _apiClient.get(
          '/exercises',
          queryParameters: {
            'limit': _batchSize,
            'offset': offset,
            'isCustom': false,
          },
        );
        final batch = (response.data as List)
            .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
            .toList();

        if (batch.isEmpty) break;
        allExercises.addAll(batch);
        offset += batch.length;
        page++;

        if (batch.length < _batchSize) break;
      }

      await _exercisesDao.upsertAll(allExercises);
      debugPrint('[SyncService] seeded ${allExercises.length} exercises');

      // Mark seed done in prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seedDoneKey, true);
    } catch (e) {
      debugPrint('[SyncService] exercise seed failed: $e');
    }
  }

  Future<void> _seedTemplatesIfNeeded({bool force = false}) async {
    final stale = await _templatesDao.isCacheStale();
    if (!force && !stale) return;

    try {
      final response = await _apiClient.get('/workouts/templates');
      final templates = (response.data as List)
          .map((j) => WorkoutTemplate.fromJson(j as Map<String, dynamic>))
          .toList();
      await _templatesDao.upsertAll(templates);
      debugPrint('[SyncService] seeded ${templates.length} templates');
    } catch (e) {
      debugPrint('[SyncService] template seed failed: $e');
    }
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Pushes all pending sessions and their sets to the server.
  /// Safe to call multiple times — uses syncStatus to avoid double-posting.
  Future<void> syncPendingSessions() async {
    final isOnline = await checkIsOnline();
    if (!isOnline) {
      debugPrint('[SyncService] offline — skipping sync');
      return;
    }

    final pending = await _sessionsDao.getPendingForSync();
    if (pending.isEmpty) {
      debugPrint('[SyncService] nothing to sync');
      return;
    }

    debugPrint('[SyncService] syncing ${pending.length} session(s)...');

    for (final session in pending) {
      await _syncSession(session);
    }
  }

  Future<void> _syncSession(PendingSession session) async {
    // Mark as syncing to prevent concurrent attempts
    await _sessionsDao.markSyncing(session.localId);

    try {
      final startedAt =
          DateTime.fromMillisecondsSinceEpoch(session.startedAt).toUtc().toIso8601String();

      // 1. Create the session on the server with client-recorded start time
      final response = await _apiClient.post('/workouts/sessions', data: {
        'notes': session.notes,
        'startedAt': startedAt,
      });

      final serverData = response.data as Map<String, dynamic>;
      final serverId = serverData['id'] as String;

      // 2. If the session has ended, close it on the server with client time
      if (session.endedAt != null) {
        final endedAt = DateTime.fromMillisecondsSinceEpoch(session.endedAt!)
            .toUtc()
            .toIso8601String();
        await _apiClient.patch('/workouts/sessions/$serverId', data: {
          'ended': true,
          'endedAt': endedAt,
        });
      }

      // 3. Update local row with server ID
      await _sessionsDao.markSessionSynced(session.localId, serverId);

      // 4. Update all sets to know the server session ID
      await _sessionsDao.updateSetsServerSessionId(session.localId, serverId);

      debugPrint('[SyncService] session ${session.localId} → server $serverId');

      // 5. Sync all sets for this session
      await _syncSetsForSession(session.localId, serverId);
    } catch (e) {
      debugPrint('[SyncService] session sync failed: $e');
      await _sessionsDao.markSessionFailed(session.localId, e.toString());
    }
  }

  Future<void> _syncSetsForSession(
      String sessionLocalId, String sessionServerId) async {
    final sets = await _sessionsDao.getPendingSetsForSession(sessionLocalId);

    for (final set in sets) {
      try {
        final response = await _apiClient.post(
          '/workouts/sessions/$sessionServerId/sets',
          data: {
            'exerciseId': set.exerciseId,
            'setNumber': set.setNumber,
            'reps': set.reps,
            'weightKg': set.weightKg,
            'rpe': set.rpe,
            'assistKg': set.assistKg,
            'durationSecs': set.durationSecs,
            'distanceM': set.distanceM,
            'speedKph': set.speedKph,
          },
        );

        final resultData = response.data as Map<String, dynamic>;
        // Response may have { set: { id: ... }, isPr: bool }
        final setData = resultData['set'] as Map<String, dynamic>?
            ?? resultData;
        final serverId = setData['id'] as String;

        await _sessionsDao.markSetSynced(set.localId, serverId);
      } catch (e) {
        debugPrint('[SyncService] set ${set.localId} sync failed: $e');
        // Don't fail the whole session for one bad set
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
  );
});
