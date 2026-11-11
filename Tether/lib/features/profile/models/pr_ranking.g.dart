// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PRRanking _$PRRankingFromJson(Map<String, dynamic> json) => PRRanking(
  rank: (json['rank'] as num).toInt(),
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  avatarPath: json['avatarPath'] as String?,
  gender: json['gender'] as String?,
  prValue: (json['prValue'] as num).toDouble(),
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  reps: (json['reps'] as num).toInt(),
  achievedDate: DateTime.parse(json['achievedDate'] as String),
  isCurrentUser: json['isCurrentUser'] as bool? ?? false,
);

Map<String, dynamic> _$PRRankingToJson(PRRanking instance) => <String, dynamic>{
  'rank': instance.rank,
  'userId': instance.userId,
  'displayName': instance.displayName,
  'avatarPath': instance.avatarPath,
  'gender': instance.gender,
  'prValue': instance.prValue,
  'weightKg': instance.weightKg,
  'reps': instance.reps,
  'achievedDate': instance.achievedDate.toIso8601String(),
  'isCurrentUser': instance.isCurrentUser,
};

PRLeaderboard _$PRLeaderboardFromJson(Map<String, dynamic> json) =>
    PRLeaderboard(
      exerciseName: json['exerciseName'] as String,
      topThree: (json['topThree'] as List<dynamic>)
          .map((e) => PRRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRanking: json['currentUserRanking'] == null
          ? null
          : PRRanking.fromJson(
              json['currentUserRanking'] as Map<String, dynamic>,
            ),
      totalRanked: (json['totalRanked'] as num).toInt(),
      genderFilter: json['genderFilter'] as String?,
    );

Map<String, dynamic> _$PRLeaderboardToJson(PRLeaderboard instance) =>
    <String, dynamic>{
      'exerciseName': instance.exerciseName,
      'topThree': instance.topThree,
      'currentUserRanking': instance.currentUserRanking,
      'totalRanked': instance.totalRanked,
      'genderFilter': instance.genderFilter,
    };

PRShowcaseData _$PRShowcaseDataFromJson(Map<String, dynamic> json) =>
    PRShowcaseData(
      benchPress: PRLeaderboard.fromJson(
        json['benchPress'] as Map<String, dynamic>,
      ),
      squat: PRLeaderboard.fromJson(json['squat'] as Map<String, dynamic>),
      deadlift: PRLeaderboard.fromJson(
        json['deadlift'] as Map<String, dynamic>,
      ),
      fetchedAt: json['fetchedAt'] == null
          ? null
          : DateTime.parse(json['fetchedAt'] as String),
    );

Map<String, dynamic> _$PRShowcaseDataToJson(PRShowcaseData instance) =>
    <String, dynamic>{
      'benchPress': instance.benchPress,
      'squat': instance.squat,
      'deadlift': instance.deadlift,
      'fetchedAt': instance.fetchedAt.toIso8601String(),
    };
