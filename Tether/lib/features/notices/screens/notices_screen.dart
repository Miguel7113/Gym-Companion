import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gym_notice.dart';
import '../providers/notices_provider.dart';
import '../widgets/create_notice_sheet.dart';

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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Gym notices',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await CreateNoticeSheet.show(context);
                if (created == true) {
                  // Provider already updated; optional snackbar
                }
              },
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryFixed,
              child: const Icon(Symbols.add, size: 22),
            )
          : null,
      body: noticesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
        error: (e, _) => Center(
          child: ConnectErrorState(
            onRetry: () => ref.read(noticesProvider.notifier).refresh(),
          ),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(noticesProvider.notifier).refresh(),
              color: AppTheme.primaryContainer,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: EmptyState(
                      icon: Symbols.campaign,
                      title: 'No notices yet',
                      message: canManage
                          ? 'Tap + to post a gym announcement'
                          : 'Announcements from your coaches will show up here',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(noticesProvider.notifier).refresh(),
            color: AppTheme.primaryContainer,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                AppTheme.stackSm,
                AppTheme.containerMargin,
                100,
              ),
              itemCount: notices.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.stackSm),
              itemBuilder: (_, i) {
                final notice = notices[i];
                return _NoticeCard(
                  notice: notice,
                  onTap: () => _openDetail(context, ref, notice, canManage),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    GymNotice notice,
    bool canManage,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeDetailScreen(
          notice: notice,
          canManage: canManage,
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final GymNotice notice;
  final VoidCallback onTap;
  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(
            color: notice.isPinned
                ? AppTheme.primaryContainer.withOpacity(0.25)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.stackSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(notice.icon, size: 12, color: notice.tagColor),
                  const SizedBox(width: 5),
                  Text(
                    notice.displayTag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: notice.tagColor,
                          fontSize: 10,
                        ),
                  ),
                  if (notice.isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Symbols.push_pin,
                      size: 12,
                      color: AppTheme.primaryContainer.withOpacity(0.8),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    notice.timeAgo,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notice.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notice.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Read more',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Symbols.arrow_forward,
                    size: 11,
                    color: AppTheme.primaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends ConsumerWidget {
  final GymNotice notice;
  final bool canManage;

  const NoticeDetailScreen({
    super.key,
    required this.notice,
    this.canManage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        actions: canManage
            ? [
                IconButton(
                  tooltip: 'Delete notice',
                  onPressed: () async {
                    final ok = await showAppConfirmDialog(
                      context,
                      icon: Symbols.delete,
                      tone: AppDialogTone.danger,
                      title: 'Delete notice?',
                      message:
                          'Members will no longer see it on Home or in Notices.',
                      confirmLabel: 'Delete',
                    );
                    if (ok == true) {
                      await ref
                          .read(noticesProvider.notifier)
                          .softDelete(notice.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Symbols.delete, size: 20),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.containerMargin,
          AppTheme.stackMd,
          AppTheme.containerMargin,
          80,
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: notice.tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: notice.tagColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(notice.icon, size: 12, color: notice.tagColor),
                const SizedBox(width: 5),
                Text(
                  notice.displayTag,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: notice.tagColor),
                ),
                if (notice.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Symbols.push_pin,
                    size: 12,
                    color: notice.tagColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),
          Text(
            notice.title,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            notice.timeAgo +
                (notice.authorDisplayName != null
                    ? ' · ${notice.authorDisplayName}'
                    : ''),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.stackMd),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: AppTheme.stackMd),
          Text(
            notice.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: AppTheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
