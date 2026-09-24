import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/gym_notice.dart';

class NoticesService {
  final ApiClient _api;
  NoticesService(this._api);

  Future<List<GymNotice>> list({int limit = 50, int offset = 0}) async {
    final response = await _api.get(
      '/notices',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (response.data as List)
        .map((j) => GymNotice.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<GymNotice> getById(String id) async {
    final response = await _api.get('/notices/$id');
    return GymNotice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GymNotice> create({
    required String title,
    required String body,
    required String tag,
    bool isPinned = false,
  }) async {
    final response = await _api.post(
      '/notices',
      data: {
        'title': title,
        'body': body,
        'tag': tag,
        'isPinned': isPinned,
      },
    );
    return GymNotice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GymNotice> update(
    String id, {
    String? title,
    String? body,
    String? tag,
    bool? isPinned,
  }) async {
    final response = await _api.patch(
      '/notices/$id',
      data: {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (tag != null) 'tag': tag,
        if (isPinned != null) 'isPinned': isPinned,
      },
    );
    return GymNotice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> softDelete(String id) async {
    await _api.delete('/notices/$id');
  }
}

final noticesServiceProvider = Provider<NoticesService>((ref) {
  return NoticesService(ref.watch(apiClientProvider));
});
