import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// connectivityProvider
//
// Riverpod StreamProvider that emits true when the device has any network
// connection, false when offline.
//
// Usage:
//   final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;
//
// The workout screens watch this to show the offline badge.
// SyncService watches this to trigger a sync when connectivity is restored.
// ─────────────────────────────────────────────────────────────────────────────
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

/// One-shot connectivity check — used by SyncService before attempting a sync.
Future<bool> checkIsOnline() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}

// ─────────────────────────────────────────────────────────────────────────────
// syncStatusProvider
//
// Emits the count of workout sessions waiting to sync.
// Drives the "X workouts pending sync" indicator on the home screen.
// ─────────────────────────────────────────────────────────────────────────────
final syncStatusProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionsDao.watchPendingCount();
});
