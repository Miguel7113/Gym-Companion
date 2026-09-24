// ─────────────────────────────────────────────────────────────────────────────
// Feed models — shapes returned by GET /social/posts
// Not using json_annotation here because the post format is flat and stable.
// ─────────────────────────────────────────────────────────────────────────────

class FeedPost {
  final String id;
  final String gymId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsStaff;
  final String? authorStaffRole;
  final String content;
  final String? imageUrl;
  // achievementType: 'pr' | 'workout_complete' | 'announcement' | ...
  final String? achievementType;
  final String? workoutSessionId;
  final Map<String, dynamic>? workoutSummary;
  final bool isOwnPost;
  final CoachCertification? coachCertification;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFlagged;
  final DateTime createdAt;

  const FeedPost({
    required this.id,
    required this.gymId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorIsStaff = false,
    this.authorStaffRole,
    required this.content,
    this.imageUrl,
    this.achievementType,
    this.workoutSessionId,
    this.workoutSummary,
    this.isOwnPost = false,
    this.coachCertification,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.isFlagged = false,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      gymId: json['gymId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String? ?? 'Member',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorIsStaff: json['authorIsStaff'] as bool? ?? false,
      authorStaffRole: json['authorStaffRole'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      achievementType: json['achievementType'] as String?,
      workoutSessionId: json['workoutSessionId'] as String?,
      workoutSummary: (json['workoutSummary'] as Map?)?.cast<String, dynamic>(),
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      coachCertification: json['coachCertification'] is Map
          ? CoachCertification.fromJson(
              (json['coachCertification'] as Map).cast<String, dynamic>(),
            )
          : null,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isFlagged: json['isFlagged'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  FeedPost copyWith({
    int? likeCount,
    bool? isLiked,
    CoachCertification? coachCertification,
  }) {
    return FeedPost(
      id: id,
      gymId: gymId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorIsStaff: authorIsStaff,
      authorStaffRole: authorStaffRole,
      content: content,
      imageUrl: imageUrl,
      achievementType: achievementType,
      workoutSessionId: workoutSessionId,
      workoutSummary: workoutSummary,
      isOwnPost: isOwnPost,
      coachCertification: coachCertification ?? this.coachCertification,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      isLiked: isLiked ?? this.isLiked,
      isFlagged: isFlagged,
      createdAt: createdAt,
    );
  }

  /// Human-readable relative time string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Tags derived from achievementType and content for the chip row
  List<String> get tags {
    if (achievementType == 'pr') {
      final prMatch = RegExp(
        r'(\d+(?:\.\d+)?kg × \d+ reps)',
      ).firstMatch(content);
      return [if (prMatch != null) prMatch.group(1)!, 'PR'];
    }
    if (achievementType == 'workout_complete') {
      return ['Workout complete'];
    }
    if (achievementType == 'announcement') return ['Announcement'];
    if (achievementType == 'class_update') return ['Class update'];
    if (achievementType == 'reminder') return ['Reminder'];
    return [];
  }
}

class CoachCertification {
  final String coachName;
  final DateTime certifiedAt;

  const CoachCertification({
    required this.coachName,
    required this.certifiedAt,
  });

  factory CoachCertification.fromJson(Map<String, dynamic> json) {
    return CoachCertification(
      coachName: json['coachName'] as String? ?? 'Coach',
      certifiedAt: DateTime.parse(json['certifiedAt'] as String),
    );
  }

  String get dateLabel =>
      '${certifiedAt.day}/${certifiedAt.month}/${certifiedAt.year}';
}

class FeedComment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const FeedComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      authorId: json['user']?['id'] as String? ?? '',
      authorName: json['user']?['displayName'] as String? ?? 'Member',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
