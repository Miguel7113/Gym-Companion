import 'package:json_annotation/json_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

part 'auth_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User — built from the Supabase JWT claims injected by auth-verify-otp.
//
// The Edge Function writes gym_id, member_id, role into
// auth.users.raw_user_meta_data, which Supabase then embeds in the JWT.
// We read them back here so there is no extra API call needed.
// ─────────────────────────────────────────────────────────────────────────────
class User {
  final String id;          // Supabase auth.users.id (UUID)
  final String gymId;       // from JWT meta: gym_id
  final String memberId;    // from JWT meta: member_id
  final String role;        // from JWT meta: role (member|coach|admin)
  final String? email;
  final String? phone;
  final String? displayName;

  const User({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.role,
    this.email,
    this.phone,
    this.displayName,
  });

  factory User.fromSupabaseSession(sb.Session session) {
    final meta = session.user.userMetadata ?? {};
    return User(
      id: session.user.id,
      gymId: meta['gym_id'] as String? ?? '',
      memberId: meta['member_id'] as String? ?? '',
      role: meta['role'] as String? ?? 'member',
      email: session.user.email,
      phone: session.user.phone,
      displayName: meta['display_name'] as String?,
    );
  }

  /// Fallback for the home screen provider which still reads currentUserProvider
  Map<String, dynamic> toJson() => {
    'id': id,
    'gymId': gymId,
    'memberId': memberId,
    'role': role,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (displayName != null) 'displayName': displayName,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Gym — fetched from Supabase gyms table via GymSelectionScreen
// ─────────────────────────────────────────────────────────────────────────────
@JsonSerializable()
class Gym {
  final String id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'primary_color')
  final String? primaryColor;
  @JsonKey(name: 'admin_email')
  final String? contactEmail;
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;

  const Gym({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.contactEmail,
    this.subscriptionStatus,
  });

  factory Gym.fromJson(Map<String, dynamic> json) => _$GymFromJson(json);
  Map<String, dynamic> toJson() => _$GymToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// DTOs sent to NestJS auth endpoints
// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable()
class RequestOtpDto {
  final String gymId;
  final String? email;
  final String? phone;
  final String? displayName;

  const RequestOtpDto({
    required this.gymId,
    this.email,
    this.phone,
    this.displayName,
  });

  factory RequestOtpDto.fromJson(Map<String, dynamic> json) =>
      _$RequestOtpDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RequestOtpDtoToJson(this);
}

@JsonSerializable()
class VerifyOtpDto {
  final String gymId;
  final String? email;
  final String? phone;
  final String token;
  final String? displayName;

  const VerifyOtpDto({
    required this.gymId,
    this.email,
    this.phone,
    required this.token,
    this.displayName,
  });

  factory VerifyOtpDto.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyOtpDtoToJson(this);
}

@JsonSerializable()
class OtpResponse {
  final String status;
  final bool? returning;

  const OtpResponse({required this.status, this.returning});

  factory OtpResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OtpResponseToJson(this);
}
