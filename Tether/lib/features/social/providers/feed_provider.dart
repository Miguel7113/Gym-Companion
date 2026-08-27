import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_models.dart';
import '../services/social_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FeedNotifier — AsyncNotifier managing the paginated feed list.
//
// Optimistic like: updates local state immediately, fires API in background,
// reverts on failure so the user never sees a stale count.
// ─────────────────────────────────────────────────────────────────────────────
class FeedNotifier extends AutoDisposeAsyncNotifier<List<FeedPost>> {
  @override
  Future<List<FeedPost>> build() => _fetch();

  Future<List<FeedPost>> _fetch() async {
    try {
      final svc = ref.read(socialServiceProvider);
      return await svc.getFeed(limit: 20, offset: 0);
    } catch (e) {
      debugFeedError(e);
      // Return empty list gracefully — screen shows empty state
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── Optimistic like ────────────────────────────────────────────────────────
  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = current[idx];
    final wasLiked = post.isLiked;
    final optimistic = List<FeedPost>.from(current);
    optimistic[idx] = post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    state = AsyncValue.data(optimistic);

    // Fire API
    try {
      final svc = ref.read(socialServiceProvider);
      await svc.toggleLike(postId);
    } catch (e) {
      debugFeedError(e);
      // Revert on failure
      state = AsyncValue.data(current);
    }
  }

  // ── Flag post ──────────────────────────────────────────────────────────────
  Future<void> flagPost(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Remove from local feed immediately
    final updated = current.where((p) => p.id != postId).toList();
    state = AsyncValue.data(updated);

    try {
      final svc = ref.read(socialServiceProvider);
      await svc.flagPost(postId);
    } catch (e) {
      debugFeedError(e);
      // Revert — put the post back
      state = AsyncValue.data(current);
    }
  }

  // ── Add post (staff create or PR share) ───────────────────────────────────
  void prependPost(FeedPost post) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([post, ...current]);
  }
}

final feedProvider =
    AsyncNotifierProvider.autoDispose<FeedNotifier, List<FeedPost>>(
  FeedNotifier.new,
);

void debugFeedError(Object e) {
  // ignore: avoid_print
  print('[FeedProvider] error: $e');
}
