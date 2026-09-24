import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

/// Backend tags (NestJS NOTICE_TAGS).
const List<String> kNoticeTags = [
  'ANNOUNCEMENT',
  'CLASS_UPDATE',
  'REMINDER',
  'EVENT',
];

class GymNotice {
  final String id;
  final String gymId;
  final String? authorUserId;
  final String? authorStaffId;
  final String title;
  final String body;
  final String tag;
  final bool isPinned;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? authorDisplayName;

  const GymNotice({
    required this.id,
    required this.gymId,
    this.authorUserId,
    this.authorStaffId,
    required this.title,
    required this.body,
    required this.tag,
    required this.isPinned,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.authorDisplayName,
  });

  factory GymNotice.fromJson(Map<String, dynamic> json) {
    final authorUser = json['authorUser'];
    String? displayName;
    if (authorUser is Map) {
      displayName = authorUser['displayName'] as String?;
    }
    return GymNotice(
      id: json['id'] as String,
      gymId: json['gymId'] as String,
      authorUserId: json['authorUserId'] as String?,
      authorStaffId: json['authorStaffId'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tag: json['tag'] as String? ?? 'ANNOUNCEMENT',
      isPinned: json['isPinned'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      authorDisplayName: displayName,
    );
  }

  String get displayTag {
    switch (tag) {
      case 'CLASS_UPDATE':
        return 'CLASS UPDATE';
      default:
        return tag;
    }
  }

  IconData get icon {
    switch (tag) {
      case 'CLASS_UPDATE':
        return Symbols.schedule;
      case 'REMINDER':
        return Symbols.notifications_active;
      case 'EVENT':
        return Symbols.emoji_events;
      case 'ANNOUNCEMENT':
      default:
        return Symbols.campaign;
    }
  }

  Color get tagColor {
    switch (tag) {
      case 'CLASS_UPDATE':
        return const Color(0xFF2196F3);
      case 'REMINDER':
        return const Color(0xFFFF9800);
      case 'EVENT':
        return const Color(0xFF9C27B0);
      case 'ANNOUNCEMENT':
      default:
        return AppTheme.primaryContainer;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(publishedAt.toUtc());
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
  }
}
