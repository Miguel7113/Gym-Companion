import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../../../features/workouts/models/workout_models.dart';

part 'sessions_dao.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionsDao
// ─────────────────────────────────────────────────────────────────────────────
// NOTE: Drift generates data classes as the table class name minus trailing 's':
//   PendingSessions table → PendingSession data class
//   PendingSets table     → PendingSet data class
// ─────────────────────────────────────────────────────────────────────────────
@DriftAccessor(tables: [PendingSessions, PendingSets])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  static const _uuid = Uuid();

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<String> createSession({
    required String gymId,
    required String userId,
    String? notes,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await into(pendingSessions).insert(PendingSessionsCompanion.insert(
      localId: localId,
      gymId: gymId,
      userId: userId,
      startedAt: now,
      createdAt: now,
      notes: Value(notes),
      syncStatus: const Value('pending'),
    ));

    return localId;
  }

  Future<void> endSession(String localId) async {
    await (update(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .write(PendingSessionsCompanion(
      endedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> updateSessionNotes(String localId, String? notes) async {
    await (update(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .write(PendingSessionsCompanion(notes: Value(notes)));
  }

  Future<void> markSyncing(String localId) async {
    await (update(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .write(const PendingSessionsCompanion(
      syncStatus: Value('syncing'),
    ));
  }

  Future<void> markSessionSynced(String localId, String serverId) async {
    await (update(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .write(PendingSessionsCompanion(
      serverId: Value(serverId),
      syncStatus: const Value('synced'),
      syncError: const Value(null),
    ));
  }

  Future<void> markSessionFailed(String localId, String error) async {
    final current = await (select(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
    final retries = (current?.retryCount ?? 0) + 1;

    await (update(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .write(PendingSessionsCompanion(
      syncStatus: const Value('failed'),
      syncError: Value(error),
      retryCount: Value(retries),
    ));
  }

  /// Returns sessions that still need to sync (max 3 attempts).
  Future<List<PendingSession>> getPendingForSync() async {
    return (select(pendingSessions)
          ..where((t) =>
              t.syncStatus.isIn(['pending', 'failed']) &
              t.retryCount.isSmallerThanValue(3)))
        .get();
  }

  /// Active session = no endedAt set.
  Future<PendingSession?> getActiveSession(String userId) async {
    return (select(pendingSessions)
          ..where((t) => t.userId.equals(userId) & t.endedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PendingSession>> getHistory(
    String userId, {
    int limit = 20,
  }) async {
    return (select(pendingSessions)
          ..where((t) => t.userId.equals(userId) & t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> getSessionCountThisWeek(String userId) async {
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final countExpr = pendingSessions.localId.count();
    final query = selectOnly(pendingSessions)
      ..addColumns([countExpr])
      ..where(pendingSessions.userId.equals(userId) &
          pendingSessions.endedAt.isNotNull() &
          pendingSessions.startedAt.isBiggerOrEqualValue(weekAgo));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> getStreak(String userId) async {
    final sessions = await (select(pendingSessions)
          ..where((t) => t.userId.equals(userId) & t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();

    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) {
          final dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
          return DateTime(dt.year, dt.month, dt.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime check = DateTime.now();
    check = DateTime(check.year, check.month, check.day);

    for (final date in dates) {
      if (date == check || date == check.subtract(const Duration(days: 1))) {
        streak++;
        check = date;
      } else {
        break;
      }
    }

    return streak;
  }

  Stream<int> watchPendingCount() {
    final countExpr = pendingSessions.localId.count();
    final query = selectOnly(pendingSessions)
      ..addColumns([countExpr])
      ..where(pendingSessions.syncStatus.isIn(['pending', 'failed']));
    return query
        .watch()
        .map((rows) => rows.first.read(countExpr) ?? 0);
  }

  Future<PendingSession?> getSessionByLocalId(String localId) async {
    return (select(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<PendingSession?> getSessionByServerId(String serverId) async {
    return (select(pendingSessions)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  /// Resolves a session id (local or server) to the local primary key.
  Future<String?> resolveLocalId(String sessionId) async {
    final byLocal = await getSessionByLocalId(sessionId);
    if (byLocal != null) return byLocal.localId;
    final byServer = await getSessionByServerId(sessionId);
    return byServer?.localId;
  }

  Future<void> deleteSession(String sessionId) async {
    final localId = await resolveLocalId(sessionId) ?? sessionId;
    await (delete(pendingSets)
          ..where((t) => t.sessionLocalId.equals(localId)))
        .go();
    await (delete(pendingSessions)
          ..where((t) => t.localId.equals(localId)))
        .go();
  }

  Future<int> getTotalEndedSessionCount(String userId) async {
    final countExpr = pendingSessions.localId.count();
    final query = selectOnly(pendingSessions)
      ..addColumns([countExpr])
      ..where(pendingSessions.userId.equals(userId) &
          pendingSessions.endedAt.isNotNull());
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> getSetsCountThisWeek(String userId) async {
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final sessions = await (select(pendingSessions)
          ..where((t) =>
              t.userId.equals(userId) &
              t.endedAt.isNotNull() &
              t.startedAt.isBiggerOrEqualValue(weekAgo)))
        .get();
    if (sessions.isEmpty) return 0;
    final localIds = sessions.map((s) => s.localId).toList();
    final countExpr = pendingSets.localId.count();
    final query = selectOnly(pendingSets)
      ..addColumns([countExpr])
      ..where(pendingSets.sessionLocalId.isIn(localIds));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  // ── Converters ─────────────────────────────────────────────────────────────

  WorkoutSession toWorkoutSession(PendingSession row,
      [List<WorkoutSet> sets = const []]) {
    return WorkoutSession(
      id: row.serverId ?? row.localId,
      userId: row.userId,
      gymId: row.gymId,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAt),
      endedAt: row.endedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.endedAt!)
          : null,
      notes: row.notes,
      sets: sets,
    );
  }

  // ── Sets ───────────────────────────────────────────────────────────────────

  Future<String> addSet({
    required String sessionLocalId,
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
    final localId = _uuid.v4();
    await into(pendingSets).insert(PendingSetsCompanion.insert(
      localId: localId,
      sessionLocalId: sessionLocalId,
      exerciseId: exerciseId,
      sessionServerId: Value(sessionServerId),
      setNumber: Value(setNumber),
      reps: Value(reps),
      weightKg: Value(weightKg),
      rpe: Value(rpe),
      assistKg: Value(assistKg),
      durationSecs: Value(durationSecs),
      distanceM: Value(distanceM),
      speedKph: Value(speedKph),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: const Value('pending'),
    ));
    return localId;
  }

  Future<List<PendingSet>> getSetsForSession(String sessionLocalId) async {
    return (select(pendingSets)
          ..where((t) => t.sessionLocalId.equals(sessionLocalId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<PendingSet>> getPendingSetsForSession(
      String sessionLocalId) async {
    return (select(pendingSets)
          ..where((t) =>
              t.sessionLocalId.equals(sessionLocalId) &
              t.syncStatus.equals('pending')))
        .get();
  }

  Future<void> markSetSynced(String localId, String serverId) async {
    await (update(pendingSets)..where((t) => t.localId.equals(localId)))
        .write(PendingSetsCompanion(
      serverId: Value(serverId),
      syncStatus: const Value('synced'),
    ));
  }

  Future<void> updateSetsServerSessionId(
      String sessionLocalId, String sessionServerId) async {
    await (update(pendingSets)
          ..where((t) => t.sessionLocalId.equals(sessionLocalId)))
        .write(PendingSetsCompanion(
      sessionServerId: Value(sessionServerId),
    ));
  }

  Future<void> deleteSet(String localId) async {
    await (delete(pendingSets)..where((t) => t.localId.equals(localId))).go();
  }

  WorkoutSet toWorkoutSet(PendingSet row) {
    return WorkoutSet(
      id: row.serverId ?? row.localId,
      sessionId: row.sessionServerId ?? row.sessionLocalId,
      exerciseId: row.exerciseId,
      setNumber: row.setNumber,
      reps: row.reps,
      weightKg: row.weightKg,
      rpe: row.rpe,
      assistKg: row.assistKg,
      durationSecs: row.durationSecs,
      distanceM: row.distanceM,
      speedKph: row.speedKph,
    );
  }
}
