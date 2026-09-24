import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/cached_media.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../models/feed_models.dart';
import '../providers/feed_provider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/create_post_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SocialScreen — Feed tab (Strava-inspired activity cards)
// ─────────────────────────────────────────────────────────────────────────────
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(navIndexProvider, (previous, next) {
      if (next == 2 && previous != 2) {
        ref.read(syncServiceProvider).syncPendingSessions().then((_) {
          ref.read(feedProvider.notifier).refresh();
        });
      }
    });
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const _FeedAppBar(),
      floatingActionButton: const _StaffFab(),
      body: feedAsync.when(
        loading: () =>
            _FeedBody(posts: List.generate(3, (_) => null), isLoading: true),
        error: (error, _) {
          debugPrint('[SocialScreen] feed error: $error');
          return EmptyState(
            icon: Symbols.cloud_off,
            title: "Can't load the feed",
            message: 'Check your connection and try again',
            actionLabel: 'Retry',
            actionIcon: Symbols.refresh,
            onAction: () => ref.read(feedProvider.notifier).refresh(),
          );
        },
        data: (posts) => _FeedBody(
          posts: posts.map((p) => p as FeedPost?).toList(),
          isLoading: false,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — matches Home / Train
// ─────────────────────────────────────────────────────────────────────────────
class _FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FeedAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppTheme.containerMargin,
      title: Text(
        'Feed',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(
              Symbols.notifications,
              size: 24,
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _FeedBody extends ConsumerWidget {
  final List<FeedPost?> posts;
  final bool isLoading;

  const _FeedBody({required this.posts, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: AppTheme.primaryContainer,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 360) {
            ref.read(feedProvider.notifier).loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (posts.isEmpty && !isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Symbols.group,
                  title: 'No posts yet',
                  message: 'Be the first to share a workout with your gym',
                  actionLabel: 'Go train',
                  actionIcon: Symbols.fitness_center,
                  onAction: () =>
                      ref.read(navIndexProvider.notifier).state = NavTab.train,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.containerMargin,
                  8,
                  AppTheme.containerMargin,
                  100,
                ),
                sliver: SliverList.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.stackMd),
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    if (post == null) {
                      return const SkeletonBox(
                        width: double.infinity,
                        height: 280,
                        radius: AppTheme.radiusXxl,
                      );
                    }
                    return _ActivityCard(post: post);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity card — Strava-style social post
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityCard extends ConsumerWidget {
  final FeedPost post;
  const _ActivityCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canCertify = user != null &&
        user.role == 'coach' &&
        !post.isOwnPost &&
        post.coachCertification == null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            post: post,
            onReport: () => _confirmFlag(context, ref),
          ),
          if (post.workoutSummary != null)
            _WorkoutActivityBody(
              post: post,
              canCertify: canCertify,
              onCertify: () =>
                  ref.read(feedProvider.notifier).certifyPost(post.id),
            )
          else if (post.imageUrl != null)
            _ImageActivityBody(post: post)
          else ...[
            if (post.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            if (post.tags.isNotEmpty) _TagChipRow(tags: post.tags),
          ],
          _PostFooter(
            post: post,
            onLikeTap: () =>
                ref.read(feedProvider.notifier).toggleLike(post.id),
            onCommentTap: () => CommentsSheet.show(context, postId: post.id),
            onFlagTap: () => _confirmFlag(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFlag(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      icon: Symbols.flag,
      tone: AppDialogTone.danger,
      title: 'Report post?',
      message:
          'It will be hidden from your feed and sent to the gym team for review.',
      confirmLabel: 'Report',
    );
    if (confirmed == true) {
      ref.read(feedProvider.notifier).flagPost(post.id);
      if (context.mounted) {
        showAppSnack(
          context,
          'Post reported and removed from your feed',
          tone: AppSnackTone.success,
        );
      }
    }
  }
}

class _PostHeader extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onReport;

  const _PostHeader({required this.post, required this.onReport});

  String get _activityLabel {
    switch (post.achievementType) {
      case 'pr':
        return 'Personal record';
      case 'workout_complete':
        return 'Completed a workout';
      case 'announcement':
        return 'Announcement';
      default:
        return post.workoutSummary != null ? 'Workout' : 'Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberProfileScreen(memberId: post.authorId),
              ),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHighest,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ClipOval(
                child: post.authorAvatarUrl != null
                    ? AppCachedImage(
                        url: post.authorAvatarUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        fallback: const Icon(
                          Symbols.person,
                          size: 20,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Symbols.person,
                        size: 20,
                        color: AppTheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemberProfileScreen(
                              memberId: post.authorId,
                            ),
                          ),
                        ),
                        child: Text(
                          post.authorName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: post.authorIsStaff
                                        ? AppTheme.primaryContainer
                                        : AppTheme.onSurface,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (post.authorIsStaff) ...[
                      const SizedBox(width: 6),
                      _StaffBadge(
                        label: post.authorStaffRole ?? 'Staff',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$_activityLabel · ${post.timeAgo}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Symbols.more_horiz,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            color: AppTheme.surfaceContainerHigh,
            onSelected: (value) {
              if (value == 'report') onReport();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Text('Report post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffBadge extends StatelessWidget {
  final String label;
  const _StaffBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final display = label.isEmpty
        ? 'Staff'
        : '${label[0].toUpperCase()}${label.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.primaryContainer.withOpacity(0.35),
        ),
      ),
      child: Text(
        display,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primaryContainer,
            ),
      ),
    );
  }
}

class _ImageActivityBody extends StatelessWidget {
  final FeedPost post;
  const _ImageActivityBody({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: AppCachedImage(
            url: post.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            fallback: Container(
              color: AppTheme.surfaceContainerLowest,
              child: const Center(
                child: Icon(
                  Symbols.image,
                  size: 40,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (post.content.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        if (post.tags.isNotEmpty) _TagChipRow(tags: post.tags),
      ],
    );
  }
}

class _WorkoutActivityBody extends StatelessWidget {
  final FeedPost post;
  final bool canCertify;
  final VoidCallback onCertify;

  const _WorkoutActivityBody({
    required this.post,
    this.canCertify = false,
    required this.onCertify,
  });

  @override
  Widget build(BuildContext context) {
    final summary = post.workoutSummary!;
    final durationSeconds = (summary['durationSeconds'] as num?)?.toInt() ?? 0;
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final duration = seconds == 0 ? '${minutes}m' : '${minutes}m ${seconds}s';
    final sets = (summary['totalSets'] as num?)?.toInt() ?? 0;
    final exercises = (summary['exerciseCount'] as num?)?.toInt() ?? 0;
    final volume = (summary['volumeKg'] as num?)?.toDouble() ?? 0;
    final exerciseNames = (summary['exerciseNames'] as List?)
            ?.whereType<String>()
            .take(3)
            .join(' · ') ??
        '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppCachedImage(
                    url: post.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: AppTheme.surfaceContainerLowest,
                      child: const Icon(
                        Symbols.image,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (post.content.trim().isNotEmpty) ...[
            Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
          // Strava-style metric strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                _WorkoutMetric(value: duration, label: 'Time'),
                _WorkoutMetric(value: '$sets', label: 'Sets'),
                _WorkoutMetric(value: '$exercises', label: 'Exercises'),
                _WorkoutMetric(
                  value: '${volume.toStringAsFixed(0)} kg',
                  label: 'Volume',
                ),
              ],
            ),
          ),
          if (exerciseNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              exerciseNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (post.coachCertification != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Symbols.verified,
                  size: 16,
                  color: AppTheme.primaryContainer,
                  fill: 1,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Certified by ${post.coachCertification!.coachName} · '
                    '${post.coachCertification!.dateLabel}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ] else if (canCertify) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onCertify,
                icon: const Icon(Symbols.verified, size: 16),
                label: const Text('Certify workout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryContainer,
                  side: BorderSide(
                    color: AppTheme.primaryContainer.withOpacity(0.45),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  final String value;
  final String label;

  const _WorkoutMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagChipRow extends StatelessWidget {
  final List<String> tags;
  const _TagChipRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((t) {
          final highlighted = t.contains('PR') || t.contains('KG');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: highlighted
                  ? AppTheme.primaryContainer.withOpacity(0.12)
                  : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: highlighted
                    ? AppTheme.primaryContainer.withOpacity(0.35)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Text(
              t,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: highlighted
                        ? AppTheme.primaryContainer
                        : AppTheme.onSurfaceVariant,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PostFooter extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onFlagTap;

  const _PostFooter({
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onFlagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Symbols.favorite,
            label: post.likeCount > 0 ? '${post.likeCount}' : 'Kudos',
            active: post.isLiked,
            onTap: onLikeTap,
          ),
          _ActionButton(
            icon: Symbols.chat_bubble,
            label: post.commentCount > 0 ? '${post.commentCount}' : 'Comment',
            onTap: onCommentTap,
          ),
          const Spacer(),
          IconButton(
            onPressed: onFlagTap,
            icon: const Icon(Symbols.flag, size: 18),
            color: AppTheme.onSurfaceVariant,
            tooltip: 'Report',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color, fill: active ? 1 : 0),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff FAB
// ─────────────────────────────────────────────────────────────────────────────
class _StaffFab extends ConsumerWidget {
  const _StaffFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !{'coach', 'admin'}.contains(user.role)) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () => CreatePostSheet.show(
        context,
        onPostCreated: (post) =>
            ref.read(feedProvider.notifier).prependPost(post),
      ),
      backgroundColor: AppTheme.primaryContainer,
      foregroundColor: AppTheme.onPrimaryFixed,
      elevation: 4,
      child: const Icon(Symbols.edit, size: 22),
    );
  }
}
