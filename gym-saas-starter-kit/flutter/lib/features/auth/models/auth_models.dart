import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
class Gym with _\$Gym {
  const factory Gym({
    required String id,
    required String name,
    required String slug,
    required String code,
    String? logoUrl,
    @Default('#FF6B35') String primaryColor,
    @Default('standard') String planTier,
    required DateTime createdAt,
  }) = _Gym;

  factory Gym.fromJson(Map<String, dynamic> json) => _\$GymFromJson(json);
}

@freezed
class GymMember with _\$GymMember {
  const factory GymMember({
    required String id,
    required String gymId,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? role,
    @Default(true) bool isActive,
    DateTime? claimedAt,
    DateTime? lastActiveAt,
  }) = _GymMember;

  factory GymMember.fromJson(Map<String, dynamic> json) => _\$GymMemberFromJson(json);
}

@freezed
class AuthState with _\$AuthState {
  const factory AuthState({
    GymMember? member,
    Gym? gym,
    @Default(false) bool isLoading,
    String? error,
  }) = _AuthState;
}
