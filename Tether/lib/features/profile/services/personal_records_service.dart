import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;
import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/personal_record.dart';
import '../models/pr_ranking.dart';
import '../models/coach_stats.dart';

class PersonalRecordsService {
  final ApiClient _apiClient;

  PersonalRecordsService(this._apiClient);

  /// Get current user's PRs (includes unverified)
  Future<List<PersonalRecord>> getMyPRs(String gymId, String token) async {
    final response = await _apiClient.get(
      '/personal-records/my-prs',
      queryParameters: {'gymId': gymId},
    );
    return (response.data as List)
        .map((json) => PersonalRecord.fromJson(json))
        .toList();
  }

  /// Get user's verified PRs (public view)
  Future<List<PersonalRecord>> getUserVerifiedPRs(
    String userId,
    String gymId,
    String token,
  ) async {
    final response = await _apiClient.get(
      '/personal-records/user/$userId',
      queryParameters: {'gymId': gymId},
    );
    return (response.data as List)
        .map((json) => PersonalRecord.fromJson(json))
        .toList();
  }

  /// Create or update a PR
  Future<PersonalRecord> upsertPR({
    required String gymId,
    required String exerciseName,
    double? weightKg,
    required int reps,
    required DateTime achievedDate,
    required String token,
  }) async {
    final response = await _apiClient.post(
      '/personal-records',
      data: {
        'gymId': gymId,
        'exerciseName': exerciseName,
        'weightKg': weightKg,
        'reps': reps,
        'achievedDate': achievedDate.toIso8601String(),
      },
    );
    return PersonalRecord.fromJson(response.data);
  }

  /// Delete own unverified PR
  Future<void> deletePR(String prId, String token) async {
    await _apiClient.delete('/personal-records/$prId');
  }

  /// Get pending PRs for coach
  Future<List<PersonalRecord>> getPendingPRs(String token) async {
    final response = await _apiClient.get('/personal-records/coach/pending');
    return (response.data as List)
        .map((json) => PersonalRecord.fromJson(json))
        .toList();
  }

  /// Verify a PR (coach only)
  Future<PersonalRecord> verifyPR(String prId, String token) async {
    final response = await _apiClient.post('/personal-records/coach/verify/$prId');
    return PersonalRecord.fromJson(response.data);
  }

  /// Reject a PR (coach only)
  Future<PersonalRecord> rejectPR(
    String prId,
    String token, {
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/personal-records/coach/reject/$prId',
      data: {'reason': reason},
    );
    return PersonalRecord.fromJson(response.data);
  }

  /// Get coach dashboard stats
  Future<CoachStats> getCoachStats(String token) async {
    final response = await _apiClient.get('/personal-records/coach/stats');
    return CoachStats.fromJson(response.data);
  }

  /// Get leaderboard for an exercise
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gymId,
    required String exercise, // 'Bench Press', 'Squat', 'Deadlift'
    String? gender,
    int limit = 10,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '/personal-records/leaderboard/$exercise',
      queryParameters: {
        'gymId': gymId,
        if (gender != null) 'gender': gender,
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => LeaderboardEntry.fromJson(json))
        .toList();
  }

  /// Get user's rank in exercise
  Future<Map<String, dynamic>> getUserRank({
    required String userId,
    required String gymId,
    required String exercise,
    String? gender,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '/personal-records/leaderboard/$exercise/rank',
      queryParameters: {
        'userId': userId,
        'gymId': gymId,
        if (gender != null) 'gender': gender,
      },
    );
    return response.data;
  }

  /// Get PR showcase data for profile screen (all 3 exercises)
  /// This is optimized to fetch top 3 + user position for each exercise
  Future<PRShowcaseData> getShowcaseData({
    required String userId,
    required String gymId,
    String? genderFilter,
    required String token,
  }) async {
    // Fetch data for all 3 exercises in parallel
    final futures = [
      _fetchExerciseShowcase(
        userId: userId,
        gymId: gymId,
        exercise: 'Bench Press',
        genderFilter: genderFilter,
      ),
      _fetchExerciseShowcase(
        userId: userId,
        gymId: gymId,
        exercise: 'Squat',
        genderFilter: genderFilter,
      ),
      _fetchExerciseShowcase(
        userId: userId,
        gymId: gymId,
        exercise: 'Deadlift',
        genderFilter: genderFilter,
      ),
    ];

    final results = await Future.wait(futures);

    return PRShowcaseData(
      benchPress: results[0],
      squat: results[1],
      deadlift: results[2],
    );
  }

  /// Helper method to fetch showcase data for one exercise
  Future<PRLeaderboard> _fetchExerciseShowcase({
    required String userId,
    required String gymId,
    required String exercise,
    String? genderFilter,
  }) async {
    try {
      // Fetch top 3
      final leaderboardResponse = await _apiClient.get(
        '/personal-records/leaderboard/$exercise',
        queryParameters: {
          'gymId': gymId,
          if (genderFilter != null && genderFilter != 'all') 'gender': genderFilter,
          'limit': '3',
        },
      );

      final topThreeEntries = (leaderboardResponse.data as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();

      // Convert to PRRanking models
      final topThree = topThreeEntries.asMap().entries.map((entry) {
        final rank = entry.key + 1; // 1-indexed
        final leaderboardEntry = entry.value;
        return PRRanking(
          rank: rank,
          userId: leaderboardEntry.userId,
          displayName: leaderboardEntry.user.displayName ?? 'Member',
          avatarPath: leaderboardEntry.user.avatarPath,
          gender: leaderboardEntry.user.gender,
          prValue: leaderboardEntry.weightKg ?? 0,
          weightKg: leaderboardEntry.weightKg,
          reps: leaderboardEntry.reps,
          achievedDate: leaderboardEntry.achievedDate,
          isCurrentUser: leaderboardEntry.userId == userId,
        );
      }).toList();

      // Fetch user's rank (if not in top 3)
      PRRanking? currentUserRanking;
      final isUserInTopThree = topThree.any((r) => r.userId == userId);

      if (!isUserInTopThree) {
        try {
          final rankResponse = await _apiClient.get(
            '/personal-records/leaderboard/$exercise/rank',
            queryParameters: {
              'userId': userId,
              'gymId': gymId,
              if (genderFilter != null && genderFilter != 'all')
                'gender': genderFilter,
            },
          );

          final rankData = rankResponse.data as Map<String, dynamic>;
          final rank = rankData['rank'] as int?;
          final pr = rankData['pr'] as Map<String, dynamic>?;

          if (rank != null && pr != null) {
            currentUserRanking = PRRanking(
              rank: rank,
              userId: userId,
              displayName: pr['user']['displayName'] ?? 'You',
              avatarPath: pr['user']['avatarPath'],
              gender: pr['user']['gender'],
              prValue: (pr['weightKg'] as num?)?.toDouble() ?? 0,
              weightKg: (pr['weightKg'] as num?)?.toDouble(),
              reps: pr['reps'] as int? ?? 0,
              achievedDate: DateTime.parse(pr['achievedDate'] as String),
              isCurrentUser: true,
            );
          }
        } catch (e) {
          // User has no verified PR for this exercise - that's OK
          debugPrint('[PRService] User not ranked in $exercise: $e');
        }
      } else {
        // User is in top 3, use that ranking
        currentUserRanking = topThree.firstWhere((r) => r.userId == userId);
      }

      // Get total ranked count (approximate from leaderboard metadata)
      int totalRanked = topThree.length;
      if (currentUserRanking != null && currentUserRanking.rank > totalRanked) {
        totalRanked = currentUserRanking.rank;
      }

      return PRLeaderboard(
        exerciseName: exercise,
        topThree: topThree,
        currentUserRanking: currentUserRanking,
        totalRanked: totalRanked,
        genderFilter: genderFilter,
      );
    } catch (e) {
      debugPrint('[PRService] Failed to fetch $exercise showcase: $e');
      // Return empty leaderboard on error
      return PRLeaderboard.empty(
        exerciseName: exercise,
        genderFilter: genderFilter,
      );
    }
  }
}

final personalRecordsServiceProvider = Provider<PersonalRecordsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PersonalRecordsService(apiClient);
});

/// Provider for PR showcase data with gender filter
/// Family provider that caches based on (userId, gymId, genderFilter)
final prShowcaseProvider = FutureProvider.family<PRShowcaseData, PRShowcaseParams>(
  (ref, params) async {
    final service = ref.watch(personalRecordsServiceProvider);
    final session = ref.watch(currentSessionProvider);
    
    if (session?.accessToken == null) {
      throw Exception('Not authenticated');
    }

    return service.getShowcaseData(
      userId: params.userId,
      gymId: params.gymId,
      genderFilter: params.genderFilter,
      token: session!.accessToken,
    );
  },
);

/// Parameters for PR showcase provider
class PRShowcaseParams {
  final String userId;
  final String gymId;
  final String? genderFilter; // null, 'all', 'male', 'female'

  PRShowcaseParams({
    required this.userId,
    required this.gymId,
    this.genderFilter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PRShowcaseParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          gymId == other.gymId &&
          genderFilter == other.genderFilter;

  @override
  int get hashCode => Object.hash(userId, gymId, genderFilter);
}
