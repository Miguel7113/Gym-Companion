import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/member_profile.dart';

class ProfileService {
  final ApiClient _api;

  ProfileService(this._api);

  Future<MemberProfile> getMemberProfile(
    String memberId, {
    int postsLimit = 20,
    int postsOffset = 0,
  }) async {
    final response = await _api.get(
      '/members/$memberId/profile',
      queryParameters: {'postsLimit': postsLimit, 'postsOffset': postsOffset},
    );
    return MemberProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateMyProfile({
    required String displayName,
    double? bodyWeightKg,
    double? heightCm,
    String? avatarPath,
    bool includeAvatar = false,
  }) async {
    await _api.patch(
      '/users/me/profile',
      data: {
        'displayName': displayName,
        'bodyWeightKg': bodyWeightKg,
        'heightCm': heightCm,
        if (includeAvatar) 'avatarPath': avatarPath,
      },
    );
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(apiClientProvider));
});

final memberProfileProvider = FutureProvider.autoDispose
    .family<MemberProfile, String>((ref, memberId) {
      return ref.watch(profileServiceProvider).getMemberProfile(memberId);
    });
