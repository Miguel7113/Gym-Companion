// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      id: json['id'] as String,
      gymId: json['gymId'] as String,
      userId: json['userId'] as String,
      exerciseName: json['exerciseName'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      reps: (json['reps'] as num).toInt(),
      achievedDate: DateTime.parse(json['achievedDate'] as String),
      status: json['status'] as String,
      verifiedByCoachId: json['verifiedByCoachId'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      submissionCount: (json['submissionCount'] as num).toInt(),
      lastSubmissionAt: DateTime.parse(json['lastSubmissionAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gymId': instance.gymId,
      'userId': instance.userId,
      'exerciseName': instance.exerciseName,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'achievedDate': instance.achievedDate.toIso8601String(),
      'status': instance.status,
      'verifiedByCoachId': instance.verifiedByCoachId,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'rejectionReason': instance.rejectionReason,
      'submissionCount': instance.submissionCount,
      'lastSubmissionAt': instance.lastSubmissionAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      id: json['id'] as String,
      gymId: json['gymId'] as String,
      userId: json['userId'] as String,
      exerciseName: json['exerciseName'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      reps: (json['reps'] as num).toInt(),
      achievedDate: DateTime.parse(json['achievedDate'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      user: LeaderboardUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gymId': instance.gymId,
      'userId': instance.userId,
      'exerciseName': instance.exerciseName,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'achievedDate': instance.achievedDate.toIso8601String(),
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'user': instance.user,
    };

LeaderboardUser _$LeaderboardUserFromJson(Map<String, dynamic> json) =>
    LeaderboardUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarPath: json['avatarPath'] as String?,
      gender: json['gender'] as String?,
    );

Map<String, dynamic> _$LeaderboardUserToJson(LeaderboardUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarPath': instance.avatarPath,
      'gender': instance.gender,
    };
