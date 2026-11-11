import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/widgets/cached_media.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/feed_models.dart';
import '../providers/feed_provider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/create_post_sheet.dart';

/// Redesigned Feed/Social screen matching Tether design system
/// Inspired by Pulse design but adapted to use Bricolage Grotesque + orange accent
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
    final p = context.tether;

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, p),
            Expanded(
              child: feedAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(context, ref),
                data: (posts) => _buildFeedBody(
                  context,
                  ref,
                  posts.map((p) => p as FeedPost?).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreatePostFab(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context, TetherPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Feed',
            style: TetherText.sans(32, w: TetherTokens.w800),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                icon: Icon(
                  Symbols.notifications,
                  size: 24,
                  color: TetherTokens.cream,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: TetherTokens.nightCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.cloud_off,
              size: 64,
              color: TetherTokens.cream.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Can't load the feed",
              style: TetherText.sans(
                20,
                color: TetherTokens.cream,
                w: TetherTokens.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: TetherText.sans(
                14,
                color: TetherTokens.cream.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => ref.read(feedProvider.notifier).refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.tether.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.refresh,
                      size: 20,
                      color: TetherTokens.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TetherText.sans(
                        16,
                        color: TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedBody(
    BuildContext context,
    WidgetRef ref,
    List<FeedPost?> posts,
  ) {
    if (posts.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: context.tether.accent,
      backgroundColor: TetherTokens.nightCard,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 360) {
            ref.read(feedProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, i) {
            final post = posts[i];
            if (post == null) {
              return Container(
                height: 400,
                decoration: BoxDecoration(
                  color: TetherTokens.nightCard.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }
            return _PostCard(post: post);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.group,
              size: 64,
              color: TetherTokens.cream.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TetherText.sans(
                20,
                color: TetherTokens.cream,
                w: TetherTokens.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a workout with your gym',
              style: TetherText.sans(
                14,
                color: TetherTokens.cream.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => ref.read(navIndexProvider.notifier).state = NavTab.train,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.tether.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.fitness_center,
                      size: 20,
                      color: TetherTokens.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Go train',
                      style: TetherText.sans(
                        16,
                        color: TetherTokens.ink,
                        w: TetherTokens.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCreatePostFab(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !{'coach', 'admin'}.contains(user.role)) {
      return null;
    }
    
    return FloatingActionButton(
      onPressed: () => CreatePostSheet.show(
        context,
        onPostCreated: (post) =>
            ref.read(feedProvider.notifier).prependPost(post),
      ),
      backgroundColor: context.tether.accent,
      foregroundColor: TetherTokens.ink,
      child: const Icon(Symbols.edit, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Card
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends ConsumerWidget {
  final FeedPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.tether;

    return Container(
      decoration: BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TetherTokens.cream.withOpacity(0.1),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header (avatar, name, time)
          _PostHeader(post: post),

          // Hero Image (if exists)
          if (post.imageUrl != null || post.workoutSummary != null)
            _PostHeroImage(post: post),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Achievement chips
                if (post.workoutSummary != null)
                  _AchievementChips(post: post),

                // Caption
                if (post.content.trim().isNotEmpty) ...[
                  if (post.workoutSummary != null) const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: TetherText.sans(
                      15,
                      color: TetherTokens.cream,
                      height: 1.4,
                    ),
                  ),
                ],

                // Workout stats
                if (post.workoutSummary != null) ...[
                  const SizedBox(height: 16),
                  _WorkoutStats(post: post),
                ],

                // Coach certification
                if (post.coachCertification != null) ...[
                  const SizedBox(height: 12),
                  _CoachCertification(cert: post.coachCertification!),
                ],
              ],
            ),
          ),

          // Actions footer
          const SizedBox(height: 12),
          _PostActions(post: post),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Header
// ─────────────────────────────────────────────────────────────────────────────
class _PostHeader extends StatelessWidget {
  final FeedPost post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberProfileScreen(memberId: post.authorId),
              ),
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.accent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: post.authorAvatarUrl != null
                    ? AppCachedImage(
                        url: post.authorAvatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        fallback: Icon(
                          Symbols.person,
                          size: 24,
                          color: TetherTokens.cream.withOpacity(0.3),
                        ),
                      )
                    : Icon(
                        Symbols.person,
                        size: 24,
                        color: TetherTokens.cream.withOpacity(0.3),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorName.toUpperCase(),
                        style: TetherText.sans(
                          16,
                          color: TetherTokens.cream,
                          w: TetherTokens.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.authorIsStaff) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: p.accent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          post.authorStaffRole?.toUpperCase() ?? 'STAFF',
                          style: TetherText.sans(
                            10,
                            color: p.accent,
                            w: TetherTokens.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.timeAgo} • ${_getActivityType(post)}',
                  style: TetherText.sans(
                    12,
                    color: TetherTokens.cream.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Menu
          IconButton(
            onPressed: () => _showPostMenu(context, post),
            icon: Icon(
              Symbols.more_horiz,
              size: 24,
              color: TetherTokens.cream.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityType(FeedPost post) {
    if (post.achievementType == 'pr') return 'Personal Record';
    if (post.workoutSummary != null) return 'Workout';
    return 'Post';
  }

  void _showPostMenu(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TetherTokens.nightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Symbols.flag, color: TetherTokens.cream),
              title: Text(
                'Report post',
                style: TetherText.sans(16, color: TetherTokens.cream),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Image
// ─────────────────────────────────────────────────────────────────────────────
class _PostHeroImage extends StatelessWidget {
  final FeedPost post;
  const _PostHeroImage({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.imageUrl == null) return const SizedBox.shrink();

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: AppCachedImage(
            url: post.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            fallback: Container(
              color: TetherTokens.ink,
              child: Icon(
                Symbols.image,
                size: 48,
                color: TetherTokens.cream.withOpacity(0.3),
              ),
            ),
          ),
        ),
        // Gradient overlay for text legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievement Chips
// ─────────────────────────────────────────────────────────────────────────────
class _AchievementChips extends StatelessWidget {
  final FeedPost post;
  const _AchievementChips({required this.post});

  @override
  Widget build(BuildContext context) {
    final summary = post.workoutSummary;
    if (summary == null) return const SizedBox.shrink();

    final chips = <Widget>[];
    final p = context.tether;

    // PR chip (if it's a PR)
    if (post.achievementType == 'pr') {
      chips.add(_buildChip(context, 'PR', isPr: true));
    }

    // Volume chip
    final volume = (summary['volumeKg'] as num?)?.toDouble() ?? 0;
    if (volume > 0) {
      chips.add(_buildChip(context, '${volume.toInt()} KG', isPr: true));
    }

    // Exercise names
    final exercises = (summary['exerciseNames'] as List?)
        ?.whereType<String>()
        .take(2)
        .toList() ??
        [];
    for (final ex in exercises) {
      chips.add(_buildChip(context, ex.toUpperCase()));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildChip(BuildContext context, String label, {bool isPr = false}) {
    final p = context.tether;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPr ? p.accent.withOpacity(0.2) : TetherTokens.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPr ? p.accent : TetherTokens.cream.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TetherText.sans(
          12,
          color: isPr ? p.accent : TetherTokens.cream,
          w: TetherTokens.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workout Stats
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutStats extends StatelessWidget {
  final FeedPost post;
  const _WorkoutStats({required this.post});

  @override
  Widget build(BuildContext context) {
    final summary = post.workoutSummary!;
    final durationSeconds = (summary['durationSeconds'] as num?)?.toInt() ?? 0;
    final minutes = durationSeconds ~/ 60;
    final sets = (summary['totalSets'] as num?)?.toInt() ?? 0;
    final exercises = (summary['exerciseCount'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _StatItem(label: 'TIME', value: '${minutes}m'),
        _StatItem(label: 'SETS', value: '$sets'),
        _StatItem(label: 'EXERCISES', value: '$exercises'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TetherText.sans(
              20,
              color: TetherTokens.cream,
              w: TetherTokens.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TetherText.sans(
              10,
              color: TetherTokens.cream.withOpacity(0.5),
              w: TetherTokens.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach Certification
// ─────────────────────────────────────────────────────────────────────────────
class _CoachCertification extends StatelessWidget {
  final CoachCertification cert;
  const _CoachCertification({required this.cert});

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Row(
      children: [
        Icon(
          Symbols.verified,
          size: 18,
          color: p.accent,
          fill: 1,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Certified by ${cert.coachName} · ${cert.dateLabel}',
            style: TetherText.sans(
              12,
              color: p.accent,
              w: TetherTokens.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Actions (like, comment, share)
// ─────────────────────────────────────────────────────────────────────────────
class _PostActions extends ConsumerWidget {
  final FeedPost post;
  const _PostActions({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.tether;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: TetherTokens.cream.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Symbols.favorite,
            label: post.likeCount > 0 ? '${post.likeCount}' : 'Like',
            active: post.isLiked,
            onTap: () => ref.read(feedProvider.notifier).toggleLike(post.id),
          ),
          _ActionButton(
            icon: Symbols.chat_bubble,
            label: post.commentCount > 0 ? '${post.commentCount}' : 'Comment',
            onTap: () => CommentsSheet.show(context, postId: post.id),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Share functionality
            },
            icon: Icon(
              Symbols.share,
              size: 20,
              color: TetherTokens.cream.withOpacity(0.5),
            ),
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
    final p = context.tether;
    final color = active ? p.accent : TetherTokens.cream.withOpacity(0.7);

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color, fill: active ? 1 : 0),
      label: Text(
        label,
        style: TetherText.sans(14, color: color, w: TetherTokens.w600),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
