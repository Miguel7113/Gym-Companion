import 'dart:convert';
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/workouts/models/workout_models.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [ExercisesCache, RecentlyUsedCache])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  static const _staleDays = 7;

  // ── Cache freshness ────────────────────────────────────────────────────────

  Future<bool> isCacheStale() async {
    final row = await (select(exercisesCache)..limit(1)).getSingleOrNull();
    if (row == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - row.cachedAt;
    return age > const Duration(days: _staleDays).inMilliseconds;
  }

  Future<int> getCacheCount() async {
    final countExpr = exercisesCache.id.count();
    final query = selectOnly(exercisesCache)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  // ── Upsert ─────────────────────────────────────────────────────────────────

  Future<void> upsertAll(List<Exercise> exercises) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      b.insertAllOnConflictUpdate(
        exercisesCache,
        exercises.map((e) => ExercisesCacheCompanion.insert(
          id: e.id,
          name: e.name,
          category: Value(e.category),
          // JSON-encoded array columns must be wrapped in Value() because
          // they have default values in the Companion (Value.absent())
          bodyParts: Value(jsonEncode(e.bodyParts)),
          targetMuscles: Value(jsonEncode(e.targetMuscles)),
          secondaryMuscles: Value(jsonEncode(e.secondaryMuscles)),
          equipments: Value(jsonEncode(e.equipments)),
          difficulty: Value(e.difficulty),
          gifUrl: Value(e.gifUrl),
          imageUrls: const Value.absent(),
          instructions: Value(jsonEncode(e.instructions)),
          overview: Value(e.overview),
          isCustom: Value(e.isCustom),
          cachedAt: now,
        )).toList(),
      );
    });
  }

  Future<void> clearCache() => delete(exercisesCache).go();

  // ── Queries ────────────────────────────────────────────────────────────────

  Future<List<Exercise>> getAll({int limit = 500}) async {
    final rows = await (select(exercisesCache)
          ..where((t) => t.isCustom.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit))
        .get();
    return rows.map(_toExercise).toList();
  }

  Future<List<Exercise>> search(String query, {int limit = 100}) async {
    final rows = await (select(exercisesCache)
          ..where((t) =>
              t.name.lower().contains(query.toLowerCase()) &
              t.isCustom.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit))
        .get();
    return rows.map(_toExercise).toList();
  }

  Future<List<Exercise>> filterByBodyPart(
    String bodyPart, {
    String? query,
    int limit = 200,
  }) async {
    final q = select(exercisesCache)
      ..where((t) =>
          t.bodyParts.like('%"$bodyPart"%') & t.isCustom.equals(false));
    if (query != null && query.isNotEmpty) {
      q.where((t) => t.name.lower().contains(query.toLowerCase()));
    }
    q
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toExercise).toList();
  }

  Future<List<Exercise>> filterByEquipment(
    List<String> equipments, {
    String? query,
    int limit = 200,
  }) async {
    if (equipments.isEmpty) return getAll(limit: limit);

    var rows = await (select(exercisesCache)
          ..where((t) => t.isCustom.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit * 3))
        .get();

    final lower = equipments.map((e) => e.toLowerCase()).toSet();
    rows = rows.where((row) {
      final rowEquips = (jsonDecode(row.equipments) as List)
          .map((e) => e.toString().toLowerCase())
          .toSet();
      return rowEquips.any(lower.contains);
    }).toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      rows = rows.where((r) => r.name.toLowerCase().contains(q)).toList();
    }

    return rows.take(limit).map(_toExercise).toList();
  }

  Future<List<Exercise>> filterCombined({
    String? bodyPart,
    List<String>? equipments,
    String? query,
    String? category,
    int limit = 200,
  }) async {
    var q = select(exercisesCache)
      ..where((t) => t.isCustom.equals(false));

    if (bodyPart != null && bodyPart.isNotEmpty) {
      q.where((t) => t.bodyParts.like('%"$bodyPart"%'));
    }
    if (category != null && category.isNotEmpty) {
      q.where((t) => t.category.lower().equals(category.toLowerCase()));
    }
    if (query != null && query.isNotEmpty) {
      q.where((t) => t.name.lower().contains(query.toLowerCase()));
    }

    q
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit * 2);

    var rows = await q.get();

    if (equipments != null && equipments.isNotEmpty) {
      final lower = equipments.map((e) => e.toLowerCase()).toSet();
      rows = rows.where((row) {
        final rowEquips = (jsonDecode(row.equipments) as List)
            .map((e) => e.toString().toLowerCase())
            .toSet();
        return rowEquips.any(lower.contains);
      }).toList();
    }

    return rows.take(limit).map(_toExercise).toList();
  }

  // ── Distinct metadata ──────────────────────────────────────────────────────

  Future<List<String>> getDistinctBodyParts() async {
    final rows = await (select(exercisesCache)
          ..where((t) => t.isCustom.equals(false)))
        .get();
    final parts = <String>{};
    for (final row in rows) {
      final list = jsonDecode(row.bodyParts) as List;
      for (final p in list) {
        if (p is String && p.isNotEmpty) parts.add(p);
      }
    }
    return parts.toList()..sort();
  }

  Future<List<String>> getDistinctEquipments() async {
    final rows = await (select(exercisesCache)
          ..where((t) => t.isCustom.equals(false)))
        .get();
    final equips = <String>{};
    for (final row in rows) {
      final list = jsonDecode(row.equipments) as List;
      for (final e in list) {
        if (e is String && e.isNotEmpty) equips.add(e);
      }
    }
    return equips.toList()..sort();
  }

  Future<Exercise?> getById(String id) async {
    final row = await (select(exercisesCache)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toExercise(row);
  }

  // ── Recently used ──────────────────────────────────────────────────────────

  Future<List<Exercise>> getRecentlyUsed(String userId, {int limit = 10}) async {
    final recentRows = await (select(recentlyUsedCache)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.usedAt)])
          ..limit(limit))
        .get();
    final exercises = <Exercise>[];
    for (final r in recentRows) {
      final ex = await getById(r.exerciseId);
      if (ex != null) exercises.add(ex);
    }
    return exercises;
  }

  Future<void> recordUsage(String userId, String exerciseId) async {
    // Read current count first, then upsert with incremented value
    final existing = await (select(recentlyUsedCache)
          ..where((t) =>
              t.exerciseId.equals(exerciseId) & t.userId.equals(userId)))
        .getSingleOrNull();

    final newCount = (existing?.useCount ?? 0) + 1;

    await into(recentlyUsedCache).insertOnConflictUpdate(
      RecentlyUsedCacheCompanion.insert(
        exerciseId: exerciseId,
        userId: userId,
        usedAt: DateTime.now().millisecondsSinceEpoch,
        useCount: Value(newCount),
      ),
    );
  }

  // ── Converter ─────────────────────────────────────────────────────────────

  Exercise _toExercise(ExercisesCacheData row) {
    List<String> decodeList(String json) {
      try {
        return (jsonDecode(json) as List).cast<String>();
      } catch (_) {
        return [];
      }
    }

    return Exercise(
      id: row.id,
      name: row.name,
      category: row.category,
      bodyParts: decodeList(row.bodyParts),
      targetMuscles: decodeList(row.targetMuscles),
      secondaryMuscles: decodeList(row.secondaryMuscles),
      equipments: decodeList(row.equipments),
      difficulty: row.difficulty,
      gifUrl: row.gifUrl,
      instructions: decodeList(row.instructions),
      overview: row.overview,
      isCustom: row.isCustom,
    );
  }
}
