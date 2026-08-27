import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/feed_models.dart';

class SocialService {
  final ApiClient _api;
  SocialService(this._api);

  Future<List<FeedPost>> getFeed({int limit = 20, int offset = 0}) async {
    final response = await _api.get('/social/posts',
        queryParameters: {'limit': limit, 'offset': offset});
    return (response.data as List)
        .map((j) => FeedPost.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _api.post('/social/posts/$postId/like');
    return response.data as Map<String, dynamic>;
  }

  Future<void> flagPost(String postId) async {
    await _api.post('/social/posts/$postId/flag');
  }

  Future<List<FeedComment>> getComments(String postId) async {
    final response = await _api.get('/social/posts/$postId/comments');
    return (response.data as List)
        .map((j) => FeedComment.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<FeedComment> createComment(String postId, String content) async {
    final response = await _api.post('/social/posts/$postId/comments',
        data: {'content': content});
    return FeedComment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/social/posts/$postId/comments/$commentId');
  }

  Future<FeedPost> createStaffPost({
    required String type,
    required String content,
    String? imageUrl,
  }) async {
    final response = await _api.post('/social/posts', data: {
      'type': type,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return FeedPost.fromJson(response.data as Map<String, dynamic>);
  }

  /// Share a PR achievement to the feed (pre-filled content)
  Future<FeedPost> sharePrToFeed({
    required String exerciseName,
    required String value,
    required String imageUrl,
  }) async {
    final response = await _api.post('/social/posts', data: {
      'type': 'pr',
      'content': 'New PR — $value on $exerciseName! 💪',
      'imageUrl': imageUrl,
    });
    return FeedPost.fromJson(response.data as Map<String, dynamic>);
  }
}

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(ref.watch(apiClientProvider));
});
