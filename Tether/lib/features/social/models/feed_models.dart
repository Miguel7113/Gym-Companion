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
  final String content;
  final String? imageUrl;
  // achievementType: 'pr' | 'announcement' | 'class_update' | 'reminder' | null
  final String? achievementType;
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
    required this.content,
    this.imageUrl,
    this.achievementType,
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
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      achievementType: json['achievementType'] as String?,
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
  }) {
    return FeedPost(
      id: id,
      gymId: gymId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorIsStaff: authorIsStaff,
      content: content,
      imageUrl: imageUrl,
      achievementType: achievementType,
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
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${(diff.inDays / 7).floor()}W AGO';
  }

  /// Tags derived from achievementType and content for the chip row
  List<String> get tags {
    if (achievementType == 'pr') {
      // Extract weight/reps from content like "New PR — 100kg × 5 reps on Bench Press"
      final prMatch = RegExp(r'(\d+(?:\.\d+)?kg × \d+ reps)').firstMatch(content);
      return [
        if (prMatch != null) prMatch.group(1)!.toUpperCase(),
        'PR',
      ];
    }
    if (achievementType == 'announcement') return ['ANNOUNCEMENT'];
    if (achievementType == 'class_update') return ['CLASS UPDATE'];
    if (achievementType == 'reminder') return ['REMINDER'];
    return [];
  }
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
