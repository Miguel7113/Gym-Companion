// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gym _$GymFromJson(Map<String, dynamic> json) => Gym(
  id: json['id'] as String,
  name: json['name'] as String,
  logoUrl: json['logo_url'] as String?,
  primaryColor: json['primary_color'] as String?,
  contactEmail: json['admin_email'] as String?,
  subscriptionStatus: json['subscription_status'] as String?,
);

Map<String, dynamic> _$GymToJson(Gym instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'logo_url': instance.logoUrl,
  'primary_color': instance.primaryColor,
  'admin_email': instance.contactEmail,
  'subscription_status': instance.subscriptionStatus,
};

RequestOtpDto _$RequestOtpDtoFromJson(Map<String, dynamic> json) =>
    RequestOtpDto(
      gymId: json['gymId'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String?,
    );

Map<String, dynamic> _$RequestOtpDtoToJson(RequestOtpDto instance) =>
    <String, dynamic>{
      'gymId': instance.gymId,
      'email': instance.email,
      'phone': instance.phone,
      'displayName': instance.displayName,
    };

VerifyOtpDto _$VerifyOtpDtoFromJson(Map<String, dynamic> json) => VerifyOtpDto(
  gymId: json['gymId'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  token: json['token'] as String,
  displayName: json['displayName'] as String?,
);

Map<String, dynamic> _$VerifyOtpDtoToJson(VerifyOtpDto instance) =>
    <String, dynamic>{
      'gymId': instance.gymId,
      'email': instance.email,
      'phone': instance.phone,
      'token': instance.token,
      'displayName': instance.displayName,
    };

OtpResponse _$OtpResponseFromJson(Map<String, dynamic> json) => OtpResponse(
  status: json['status'] as String,
  returning: json['returning'] as bool?,
);

Map<String, dynamic> _$OtpResponseToJson(OtpResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'returning': instance.returning,
    };
