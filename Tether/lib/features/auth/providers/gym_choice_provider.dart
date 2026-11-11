import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';

const _lastGymKey = 'auth.last_gym_id';

final gymsProvider = FutureProvider.autoDispose<List<Gym>>((ref) {
  return ref.read(authServiceProvider).getGyms();
});

final lastGymIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_lastGymKey);
});

/// The gym this phone signed in to last, once the gym list has loaded.
final lastGymProvider = Provider.autoDispose<Gym?>((ref) {
  final gyms = ref.watch(gymsProvider).valueOrNull;
  final lastId = ref.watch(lastGymIdProvider).valueOrNull;
  if (gyms == null || lastId == null) return null;
  return gyms.where((g) => g.id == lastId).firstOrNull;
});

Future<void> rememberGym(WidgetRef ref, Gym gym) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastGymKey, gym.id);
  ref.invalidate(lastGymIdProvider);
}
