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
  static const _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<FeedPost>> build() async {
    _offset = 0;
    _hasMore = true;
    return _fetch();
  }

  Future<List<FeedPost>> _fetch() async {
    try {
      final svc = ref.read(socialServiceProvider);
      final posts = await svc.getFeed(limit: _pageSize, offset: _offset);
      _hasMore = posts.length == _pageSize;
      _offset = posts.length;
      return posts;
    } catch (e) {
      debugFeedError(e);
      rethrow;
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.valueOrNull == null) return;
    _isLoadingMore = true;
    try {
      final svc = ref.read(socialServiceProvider);
      final next = await svc.getFeed(limit: _pageSize, offset: _offset);
      final current = state.valueOrNull ?? const <FeedPost>[];
      _hasMore = next.length == _pageSize;
      _offset += next.length;
      state = AsyncValue.data([...current, ...next]);
    } catch (e) {
      debugFeedError(e);
    } finally {
      _isLoadingMore = false;
    }
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

  Future<void> certifyPost(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final certification = await ref
          .read(socialServiceProvider)
          .certifyPost(postId);
      final updated = current
          .map(
            (post) => post.id == postId
                ? post.copyWith(coachCertification: certification)
                : post,
          )
          .toList();
      state = AsyncValue.data(updated);
    } catch (e) {
      debugFeedError(e);
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
