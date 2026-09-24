import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gym_notice.dart';
import '../services/notices_service.dart';

/// Gym notices for Home + Notices screens (not the social feed).
final noticesProvider =
    AsyncNotifierProvider.autoDispose<NoticesNotifier, List<GymNotice>>(
  NoticesNotifier.new,
);

class NoticesNotifier extends AutoDisposeAsyncNotifier<List<GymNotice>> {
  @override
  Future<List<GymNotice>> build() async {
    ref.watch(authStateStreamProvider);
    if (ref.read(currentUserProvider) == null) return [];
    return ref.read(noticesServiceProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(noticesServiceProvider).list();
    });
  }

  Future<GymNotice> create({
    required String title,
    required String body,
    required String tag,
    bool isPinned = false,
  }) async {
    final notice = await ref.read(noticesServiceProvider).create(
          title: title,
          body: body,
          tag: tag,
          isPinned: isPinned,
        );
    final current = state.valueOrNull ?? <GymNotice>[];
    final merged = <GymNotice>[
      notice,
      ...current.where((n) => n.id != notice.id),
    ];
    merged.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    state = AsyncData(merged);
    return notice;
  }

  Future<void> softDelete(String id) async {
    await ref.read(noticesServiceProvider).softDelete(id);
    final current = state.valueOrNull ?? <GymNotice>[];
    state = AsyncData(current.where((n) => n.id != id).toList());
  }
}
