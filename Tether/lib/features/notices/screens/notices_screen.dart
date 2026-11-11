import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gym_notice.dart';
import '../providers/notices_provider.dart';
import '../widgets/create_notice_sheet.dart';

/// Redesigned Notices screen matching foundry aesthetic
/// Dark #131211 + cream #F0EBE1 + orange #FF5A1F
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  bool _canManage(String? role) =>
      role != null && {'coach', 'admin'}.contains(role.toLowerCase());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);
    final user = ref.watch(currentUserProvider);
    final canManage = _canManage(user?.role);

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: TetherTokens.ink,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4DFD3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: TetherTokens.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GYM NOTICES',
                      style: TetherText.sans(
                        20,
                        color: TetherTokens.cream,
                        w: TetherTokens.w800,
                      ),
                    ),
                  ),
                  if (canManage)
                    GestureDetector(
                      onTap: () async {
                        final created = await CreateNoticeSheet.show(context);
                        if (created == true) {
                          ref.invalidate(noticesProvider);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TetherTokens.defaultAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: TetherTokens.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          noticesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: TetherTokens.defaultAccent,
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load notices',
                      style: TetherText.sans(
                        16,
                        color: TetherTokens.cream,
                        w: TetherTokens.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => ref.invalidate(noticesProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: TetherTokens.defaultAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Retry',
                          style: TetherText.sans(
                            14,
                            color: TetherTokens.ink,
                            w: TetherTokens.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (notices) {
              if (notices.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.campaign,
                          size: 48,
                          color: TetherTokens.cream.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notices yet',
                          style: TetherText.sans(
                            18,
                            color: TetherTokens.cream,
                            w: TetherTokens.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          canManage
                              ? 'Tap + to post an announcement'
                              : 'Announcements will show up here',
                          style: TetherText.sans(
                            14,
                            color: TetherTokens.cream.withOpacity(0.5),
                            w: TetherTokens.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notice = notices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNoticeCard(
                          context,
                          ref,
                          notice,
                          canManage,
                        ),
                      );
                    },
                    childCount: notices.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(
    BuildContext context,
    WidgetRef ref,
    GymNotice notice,
    bool canManage,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DFD3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and time
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TetherTokens.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForTag(notice.tag),
                  size: 18,
                  color: _getColorForTag(notice.tag),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.authorDisplayName ?? 'Admin',
                      style: TetherText.sans(
                        12,
                        color: TetherTokens.ink.withOpacity(0.6),
                        w: TetherTokens.w600,
                      ),
                    ),
                    Text(
                      notice.timeAgo,
                      style: TetherText.sans(
                        11,
                        color: TetherTokens.ink.withOpacity(0.4),
                        w: TetherTokens.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                GestureDetector(
                  onTap: () => _showDeleteDialog(context, ref, notice),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: TetherTokens.ink.withOpacity(0.4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            notice.title,
            style: TetherText.sans(
              16,
              color: TetherTokens.ink,
              w: TetherTokens.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Body
          Text(
            notice.body,
            style: TetherText.sans(
              14,
              color: TetherTokens.ink.withOpacity(0.7),
              w: TetherTokens.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTag(String tag) {
    switch (tag.toUpperCase()) {
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

  Color _getColorForTag(String tag) {
    switch (tag.toUpperCase()) {
      case 'CLASS_UPDATE':
        return const Color(0xFF2196F3);
      case 'REMINDER':
        return const Color(0xFFFF9800);
      case 'EVENT':
        return const Color(0xFF9C27B0);
      case 'ANNOUNCEMENT':
      default:
        return TetherTokens.defaultAccent;
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    GymNotice notice,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE4DFD3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Notice',
          style: TetherText.sans(
            18,
            color: TetherTokens.ink,
            w: TetherTokens.w800,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this notice? This cannot be undone.',
          style: TetherText.sans(
            14,
            color: TetherTokens.ink.withOpacity(0.7),
            w: TetherTokens.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TetherText.sans(
                14,
                color: TetherTokens.ink.withOpacity(0.6),
                w: TetherTokens.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: Add delete method to noticesProvider.notifier
                // await ref.read(noticesProvider.notifier).deleteNotice(notice.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete feature coming soon')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TetherText.sans(
                14,
                color: const Color(0xFFFF5A1F),
                w: TetherTokens.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
