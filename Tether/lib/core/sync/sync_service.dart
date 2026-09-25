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
import '../../features/social/services/pending_workout_share_queue.dart';

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
  Future<void>? _seedInFlight;

  // ── Seed ──────────────────────────────────────────────────────────────────

  /// Fetches all exercises and templates from the server and writes them to
  /// the local cache. Safe to call multiple times — skips if already seeded
  /// and cache is fresh.
  ///
  /// Pass [force] = true to re-seed even if cache is fresh (e.g. after a
  /// manual "refresh" button tap).
  Future<void> seedIfNeeded({bool force = false}) {
    final existing = _seedInFlight;
    if (existing != null) return existing;

    final future = _seedIfNeeded(force: force);
    _seedInFlight = future;
    return future.whenComplete(() {
      if (identical(_seedInFlight, future)) _seedInFlight = null;
    });
  }

  Future<bool> isExerciseSeedComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seedDoneKey) ?? false;
  }

  Future<void> _seedIfNeeded({required bool force}) async {
    final isOnline = await checkIsOnline();
    if (!isOnline) {
      debugPrint('[SyncService] offline — skipping seed');
      return;
    }

    // Check if we need to seed exercises
    final cacheStale = await _exercisesDao.isCacheStale();
    final prefs = await SharedPreferences.getInstance();
    final seedCompleted = prefs.getBool(_seedDoneKey) ?? false;
    if (!force && seedCompleted && !cacheStale) {
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
    await _syncPendingWorkoutData();
    await _syncPendingWorkoutShares();
  }

  // Every logged set and every Finish tap triggers a sync. Running two at
  // once creates duplicate server sessions/sets and can overwrite a freshly
  // ended session with a stale "synced" status, so runs are serialised: a
  // call made mid-run schedules one more pass and shares the same future.
  Future<void>? _dataSyncInFlight;
  bool _dataSyncRerun = false;
  Future<void>? _shareSyncInFlight;
  bool _shareSyncRerun = false;

  /// Session + set upload only (no feed share queue).
  Future<void> _syncPendingWorkoutData() {
    final existing = _dataSyncInFlight;
    if (existing != null) {
      _dataSyncRerun = true;
      return existing;
    }
    final run = () async {
      try {
        do {
          _dataSyncRerun = false;
          await _runWorkoutDataSync();
        } while (_dataSyncRerun);
      } finally {
        _dataSyncInFlight = null;
      }
    }();
    _dataSyncInFlight = run;
    return run;
  }

  Future<void> _runWorkoutDataSync() async {
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
      var serverId = session.serverId;

      // A session may already exist remotely while newly logged sets are
      // still pending. Reuse its ID instead of creating a duplicate session.
      if (serverId == null) {
        final startedAt = DateTime.fromMillisecondsSinceEpoch(
          session.startedAt,
        ).toUtc().toIso8601String();
        final response = await _apiClient.post(
          '/workouts/sessions',
          data: {
            'notes': session.notes,
            'startedAt': startedAt,
            if (session.templateId != null) 'templateId': session.templateId,
          },
        );
        final serverData = response.data as Map<String, dynamic>;
        serverId = serverData['id'] as String;
      }

      // Always push endedAt when the local session is finished so share
      // cannot race ahead of a session that only exists as "in progress"
      // on the server.
      if (session.endedAt != null) {
        final endedAt = DateTime.fromMillisecondsSinceEpoch(
          session.endedAt!,
        ).toUtc().toIso8601String();
        await _apiClient.patch(
          '/workouts/sessions/$serverId',
          data: {'ended': true, 'endedAt': endedAt},
        );
      }

      // Update local row with server ID before uploading its sets. If the
      // session was ended or renamed while this request was in flight, keep
      // it pending so the next pass pushes the newer state.
      final fresh = await _sessionsDao.getSessionByLocalId(session.localId);
      final changedMeanwhile = fresh != null &&
          (fresh.endedAt != session.endedAt || fresh.notes != session.notes);
      if (changedMeanwhile) {
        await _sessionsDao.markSessionPendingWithServerId(
          session.localId,
          serverId,
        );
        _dataSyncRerun = true;
      } else {
        await _sessionsDao.markSessionSynced(session.localId, serverId);
      }

      // Update all sets to know the server session ID.
      await _sessionsDao.updateSetsServerSessionId(session.localId, serverId);

      debugPrint('[SyncService] session ${session.localId} → server $serverId');

      // Sync all sets for this session.
      await _syncSetsForSession(session.localId, serverId);
    } catch (e) {
      debugPrint('[SyncService] session sync failed: $e');
      await _sessionsDao.markSessionFailed(session.localId, e.toString());
    }
  }

  Future<void> _syncSetsForSession(
    String sessionLocalId,
    String sessionServerId,
  ) async {
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
        final setData =
            resultData['set'] as Map<String, dynamic>? ?? resultData;
        final serverId = setData['id'] as String;

        // The user may have un-ticked the set while it was uploading.
        if (!await _sessionsDao.setExists(set.localId)) {
          await _apiClient.delete('/workouts/sets/$serverId');
          continue;
        }
        await _sessionsDao.markSetSynced(set.localId, serverId);
      } catch (e) {
        debugPrint('[SyncService] set ${set.localId} sync failed: $e');
        // Don't fail the whole session for one bad set
      }
    }
  }

  /// Syncs the session (and its sets) until the server copy is ready to share.
  /// Returns the server session id, or null when offline / still pending.
  Future<String?> ensureSessionReadyForShare(String sessionId) async {
    if (!await checkIsOnline()) return null;

    final localId = await _sessionsDao.resolveLocalId(sessionId);
    if (localId == null) return null;

    for (var attempt = 0; attempt < 10; attempt++) {
      await _syncPendingWorkoutData();

      final session = await _sessionsDao.getSessionByLocalId(localId);
      if (session?.serverId != null &&
          session!.endedAt != null &&
          session.syncStatus == 'synced') {
        final pendingSets =
            await _sessionsDao.getPendingSetsForSession(localId);
        if (pendingSets.isEmpty) {
          return session.serverId;
        }
      }

      if (attempt < 9) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
    }

    return null;
  }

  Future<void> _syncPendingWorkoutShares() {
    final existing = _shareSyncInFlight;
    if (existing != null) {
      _shareSyncRerun = true;
      return existing;
    }
    final run = () async {
      try {
        do {
          _shareSyncRerun = false;
          await _runWorkoutShareSync();
        } while (_shareSyncRerun);
      } finally {
        _shareSyncInFlight = null;
      }
    }();
    _shareSyncInFlight = run;
    return run;
  }

  Future<void> _runWorkoutShareSync() async {
    final isOnline = await checkIsOnline();
    if (!isOnline) return;

    final queue = PendingWorkoutShareQueue(_db);
    final entries = await queue.list();

    for (final entry in entries) {
      final localId = await _sessionsDao.resolveLocalId(entry.sessionId);
      if (localId == null) {
        await queue.remove(entry.id);
        continue;
      }

      final serverId = await ensureSessionReadyForShare(entry.sessionId);
      if (serverId == null) {
        continue;
      }

      try {
        await _apiClient.post(
          '/social/workout-sessions/$serverId/share',
          data: {
            if (entry.content?.trim().isNotEmpty == true)
              'content': entry.content!.trim(),
            if (entry.imagePath != null) 'imagePath': entry.imagePath,
          },
        );
        await queue.remove(entry.id);
        debugPrint('[SyncService] shared workout ${entry.sessionId} to feed');
      } catch (e) {
        debugPrint('[SyncService] workout share ${entry.sessionId} failed: $e');
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
