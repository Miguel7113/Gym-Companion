import 'package:json_annotation/json_annotation.dart';

part 'personal_record.g.dart';

@JsonSerializable()
class PersonalRecord {
  final String id;
  final String gymId;
  final String userId;
  final String exerciseName;
  final double? weightKg;
  final int reps;
  final DateTime achievedDate;
  final String status; // 'pending', 'verified', 'rejected'
  final String? verifiedByCoachId;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final int submissionCount;
  final DateTime lastSubmissionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalRecord({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.exerciseName,
    this.weightKg,
    required this.reps,
    required this.achievedDate,
    required this.status,
    this.verifiedByCoachId,
    this.verifiedAt,
    this.rejectionReason,
    required this.submissionCount,
    required this.lastSubmissionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get displayText {
    final weight = weightKg != null ? '${weightKg}kg ' : '';
    return '$exerciseName - $weight$reps reps';
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);
}

@JsonSerializable()
class LeaderboardEntry {
  final String id;
  final String gymId;
  final String userId;
  final String exerciseName;
  final double? weightKg;
  final int reps;
  final DateTime achievedDate;
  final DateTime? verifiedAt;
  final LeaderboardUser user;

  LeaderboardEntry({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.exerciseName,
    this.weightKg,
    required this.reps,
    required this.achievedDate,
    this.verifiedAt,
    required this.user,
  });

  String get displayText {
    final weight = weightKg != null ? '${weightKg}kg ' : '';
    return '$weight$reps reps';
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}

@JsonSerializable()
class LeaderboardUser {
  final String id;
  final String? displayName;
  final String? avatarPath;
  final String? gender;

  LeaderboardUser({
    required this.id,
    this.displayName,
    this.avatarPath,
    this.gender,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardUserFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardUserToJson(this);
}
