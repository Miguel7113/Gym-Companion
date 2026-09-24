import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../api_client.dart';
import '../database/app_database.dart';
import 'sync_service.dart';

const String syncTaskName = 'tetherSyncPendingWorkouts';
const String syncTaskUniqueName = 'tether.sync.pending';

/// Entry point for Workmanager — must be top-level.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTaskName) {
      await runBackgroundSync();
      return true;
    }
    return false;
  });
}

/// Runs pending workout sync outside the main isolate (no Riverpod).
Future<void> runBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(apiAccessTokenKey);
  if (token == null || token.isEmpty) return;

  final apiClient = await ApiClient.createForBackground();
  final db = AppDatabase();
  try {
    final sync = SyncService(db, apiClient);
    await sync.syncPendingSessions();
  } finally {
    await db.close();
  }
}

Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    syncTaskUniqueName,
    syncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

Future<void> cancelBackgroundSync() async {
  await Workmanager().cancelByUniqueName(syncTaskUniqueName);
}
