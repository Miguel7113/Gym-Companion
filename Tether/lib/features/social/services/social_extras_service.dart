import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_provider.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/services/workout_service.dart';

class GymCoach {
  final String userId;
  final String displayName;
  final String role;
  final String? email;
  final int programCount;
  final bool isTrainingNow;

  const GymCoach({
    required this.userId,
    required this.displayName,
    required this.role,
    this.email,
    this.programCount = 0,
    this.isTrainingNow = false,
  });

  factory GymCoach.fromJson(Map<String, dynamic> json) => GymCoach(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? 'Coach',
        role: json['role'] as String? ?? 'coach',
        email: json['email'] as String?,
        programCount: (json['programCount'] as num?)?.toInt() ?? 0,
        isTrainingNow: json['isTrainingNow'] as bool? ?? false,
      );
}

/// Peer on the gym floor (not coach/admin staff).
class GymMemberDirectoryEntry {
  final String userId;
  final String displayName;
  final String? email;
  final bool isTrainingNow;
  /// none | pending_outgoing | pending_incoming | active
  final String buddyStatus;
  final String? buddyLinkId;

  const GymMemberDirectoryEntry({
    required this.userId,
    required this.displayName,
    this.email,
    this.isTrainingNow = false,
    this.buddyStatus = 'none',
    this.buddyLinkId,
  });

  factory GymMemberDirectoryEntry.fromJson(Map<String, dynamic> json) =>
      GymMemberDirectoryEntry(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? 'Member',
        email: json['email'] as String?,
        isTrainingNow: json['isTrainingNow'] as bool? ?? false,
        buddyStatus: json['buddyStatus'] as String? ?? 'none',
        buddyLinkId: json['buddyLinkId'] as String?,
      );

  bool get isBuddy => buddyStatus == 'active';
  bool get canRequestBuddy => buddyStatus == 'none';
}

class BuddyLink {
  final String id;
  final String status;
  final bool isIncoming;
  final String otherUserId;
  final String otherDisplayName;

  const BuddyLink({
    required this.id,
    required this.status,
    required this.isIncoming,
    required this.otherUserId,
    required this.otherDisplayName,
  });

  factory BuddyLink.fromJson(Map<String, dynamic> json) {
    final other = json['otherUser'] as Map<String, dynamic>? ?? {};
    return BuddyLink(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      isIncoming: json['isIncoming'] as bool? ?? false,
      otherUserId: other['id'] as String? ?? '',
      otherDisplayName: other['displayName'] as String? ?? 'Member',
    );
  }
}

class AppNotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) =>
      AppNotificationItem(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'general',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'] as String)
            : null,
      );
}

class SocialExtrasService {
  SocialExtrasService(this._ref);
  final Ref _ref;

  Future<List<GymCoach>> listCoaches() async {
    final response = await _ref.read(apiClientProvider).get('/auth/coaches');
    return (response.data as List)
        .map((j) => GymCoach.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<GymMemberDirectoryEntry>> listMemberDirectory({String? q}) async {
    final response = await _ref.read(apiClientProvider).get(
          '/members/directory',
          queryParameters: {
            if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          },
        );
    return (response.data as List)
        .map((j) => GymMemberDirectoryEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkoutTemplate>> listCoachPrograms(String coachUserId) async {
    return _ref.read(workoutServiceProvider).listGymPrograms(
          coachUserId: coachUserId,
        );
  }

  Future<List<BuddyLink>> listBuddies() async {
    final response = await _ref.read(apiClientProvider).get('/buddies');
    return (response.data as List)
        .map((j) => BuddyLink.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchBuddyCandidates(String q) async {
    final response = await _ref.read(apiClientProvider).get(
          '/buddies/search',
          queryParameters: {'q': q},
        );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> requestBuddy(String toUserId) async {
    await _ref.read(apiClientProvider).post(
      '/buddies/request',
      data: {'toUserId': toUserId},
    );
  }

  Future<void> acceptBuddy(String id) async {
    await _ref.read(apiClientProvider).post('/buddies/$id/accept');
  }

  Future<void> declineBuddy(String id) async {
    await _ref.read(apiClientProvider).post('/buddies/$id/decline');
  }

  Future<void> cancelBuddy(String id) async {
    await _ref.read(apiClientProvider).post('/buddies/$id/cancel');
  }

  Future<List<AppNotificationItem>> listNotifications() async {
    final response = await _ref.read(apiClientProvider).get('/notifications');
    return (response.data as List)
        .map((j) => AppNotificationItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _ref.read(apiClientProvider).post('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _ref.read(apiClientProvider).post('/notifications/read-all');
  }
}

final socialExtrasServiceProvider = Provider<SocialExtrasService>((ref) {
  return SocialExtrasService(ref);
});

final homeMembersDirectoryProvider =
    FutureProvider<List<GymMemberDirectoryEntry>>((ref) async {
  return ref.read(socialExtrasServiceProvider).listMemberDirectory();
});

final homeCoachesProvider = FutureProvider<List<GymCoach>>((ref) async {
  return ref.read(socialExtrasServiceProvider).listCoaches();
});
