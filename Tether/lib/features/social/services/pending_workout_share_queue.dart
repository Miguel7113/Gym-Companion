import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class PendingWorkoutShare {
  final String id;
  final String sessionId;
  final String? content;
  final String? imagePath;

  const PendingWorkoutShare({
    required this.id,
    required this.sessionId,
    this.content,
    this.imagePath,
  });

  factory PendingWorkoutShare.fromJson(Map<String, dynamic> json) {
    return PendingWorkoutShare(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      content: json['content'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    if (content != null) 'content': content,
    if (imagePath != null) 'imagePath': imagePath,
  };
}

/// Small persistent outbox for workout shares that are requested offline or
/// before the local session has received its server ID.
class PendingWorkoutShareQueue {
  static const _uuid = Uuid();
  final AppDatabase _db;

  PendingWorkoutShareQueue(this._db);

  Future<List<PendingWorkoutShare>> list() async {
    final rows = await (_db.select(
      _db.queuedWorkoutShares,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
    return rows
        .map(
          (row) => PendingWorkoutShare(
            id: row.id,
            sessionId: row.sessionId,
            content: row.content,
            imagePath: row.imagePath,
          ),
        )
        .toList();
  }

  Future<void> enqueue({
    required String sessionId,
    String? content,
    String? imagePath,
  }) async {
    final existing = await (_db.select(
      _db.queuedWorkoutShares,
    )..where((row) => row.sessionId.equals(sessionId))).getSingleOrNull();
    if (existing != null) return;

    await _db
        .into(_db.queuedWorkoutShares)
        .insert(
          QueuedWorkoutSharesCompanion.insert(
            id: _uuid.v4(),
            sessionId: sessionId,
            content: Value(content),
            imagePath: Value(imagePath),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> remove(String id) async {
    await (_db.delete(
      _db.queuedWorkoutShares,
    )..where((row) => row.id.equals(id))).go();
  }
}
