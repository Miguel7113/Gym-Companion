import 'dart:convert';
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/workouts/models/workout_models.dart';

part 'templates_dao.g.dart';

@DriftAccessor(tables: [WorkoutTemplatesCache])
class TemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TemplatesDaoMixin {
  TemplatesDao(super.db);

  static const _staleDays = 7;

  Future<bool> isCacheStale() async {
    final row =
        await (select(workoutTemplatesCache)..limit(1)).getSingleOrNull();
    if (row == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - row.cachedAt;
    return age > const Duration(days: _staleDays).inMilliseconds;
  }

  Future<int> getCacheCount() async {
    final countExpr = workoutTemplatesCache.id.count();
    final query = selectOnly(workoutTemplatesCache)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<void> upsertAll(List<WorkoutTemplate> templates) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      b.insertAllOnConflictUpdate(
        workoutTemplatesCache,
        templates.map((t) => WorkoutTemplatesCacheCompanion.insert(
          id: t.id,
          name: t.name,
          description: Value(t.description),
          category: Value(t.category),
          difficulty: Value(t.difficulty),
          durationMins: Value(t.durationMins),
          source: Value(t.source),
          imageUrl: Value(t.imageUrl),
          // exercisesJson has a default in the Companion — must wrap in Value()
          exercisesJson: Value(
            jsonEncode(t.exercises.map((e) => e.toJson()).toList()),
          ),
          isActive: Value(t.isActive),
          cachedAt: now,
        )).toList(),
      );
    });
  }

  Future<void> clearCache() => delete(workoutTemplatesCache).go();

  Future<List<WorkoutTemplate>> getAll() async {
    final rows = await (select(workoutTemplatesCache)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toTemplate).toList();
  }

  Future<List<WorkoutTemplate>> getBySource(String source) async {
    final rows = await (select(workoutTemplatesCache)
          ..where((t) => t.source.equals(source) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toTemplate).toList();
  }

  Future<List<WorkoutTemplate>> getSystemAndGym() async {
    final rows = await (select(workoutTemplatesCache)
          ..where((t) =>
              t.source.isIn(['system', 'gym']) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toTemplate).toList();
  }

  WorkoutTemplate _toTemplate(WorkoutTemplatesCacheData row) {
    List<WorkoutTemplateExercise> exercises = [];
    try {
      final list = jsonDecode(row.exercisesJson) as List;
      exercises = list
          .map((j) =>
              WorkoutTemplateExercise.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      exercises = [];
    }

    return WorkoutTemplate(
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      difficulty: row.difficulty,
      durationMins: row.durationMins,
      source: row.source,
      imageUrl: row.imageUrl,
      isActive: row.isActive,
      exercises: exercises,
    );
  }
}
