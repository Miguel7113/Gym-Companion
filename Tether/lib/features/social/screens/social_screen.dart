import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../models/feed_models.dart';
import '../providers/feed_provider.dart';
import '../services/social_service.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/create_post_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SocialScreen — FEED tab
// Wired to GET /social/posts. Falls back to empty state when unauthenticated
// (SKIP_LOGIN_FOR_TESTING mode).
// ─────────────────────────────────────────────────────────────────────────────
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _SocialAppBar(),
      floatingActionButton: _StaffFab(),
      body: feedAsync.when(
        loading: () => _FeedBody(
            posts: List.generate(3, (_) => null), isLoading: true),
        error: (_, __) => _FeedBody(posts: const [], isLoading: false),
        data: (posts) =>
            _FeedBody(posts: posts.map((p) => p as FeedPost?).toList(),
                isLoading: false),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — pull-to-refresh list
// ─────────────────────────────────────────────────────────────────────────────
class _FeedBody extends ConsumerWidget {
  final List<FeedPost?> posts; // null = skeleton
  final bool isLoading;

  const _FeedBody({required this.posts, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: AppTheme.primaryContainer,
      backgroundColor: AppTheme.surfaceContainerHigh,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppTheme.containerMargin,
              right: AppTheme.containerMargin,
              top: AppTheme.stackMd,
            ),
            sliver: SliverToBoxAdapter(
              child: Text('TETHER FEED',
                  style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.stackMd)),

          if (posts.isEmpty && !isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.group, size: 48,
                        color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('NO POSTS YET',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('Be the first to share a workout',
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.containerMargin),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.stackMd),
                itemBuilder: (context, i) {
                  final post = posts[i];
                  if (post == null) {
                    return SkeletonBox(
                        width: double.infinity,
                        height: 300,
                        radius: AppTheme.radiusXxl);
                  }
                  return _FeedPostCard(post: post);
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed post card — wired to real FeedPost model
// ─────────────────────────────────────────────────────────────────────────────
class _FeedPostCard extends ConsumerWidget {
  final FeedPost post;
  const _FeedPostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post),
          if (post.imageUrl != null)
            _PostImage(post: post)
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter, 0, AppTheme.gutter, AppTheme.stackSm),
              child: Text(post.content,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.onSurface)),
            ),
            if (post.tags.isNotEmpty) _TagChipRow(tags: post.tags),
          ],
          _PostFooter(
            post: post,
            onLikeTap: () => ref.read(feedProvider.notifier).toggleLike(post.id),
            onCommentTap: () => CommentsSheet.show(context, postId: post.id),
            onFlagTap: () => _confirmFlag(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFlag(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl)),
        title: Text('Report Post',
            style: Theme.of(context).textTheme.headlineMedium),
        content: Text(
          'This post will be removed from your feed and sent to the gym moderation queue.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Report',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(feedProvider.notifier).flagPost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post reported and removed from feed')),
        );
      }
    }
  }
}

// ─── Post header ──────────────────────────────────────────────────────────────
class _PostHeader extends StatelessWidget {
  final FeedPost post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: AppTheme.stackSm),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceContainerHighest,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipOval(
              child: post.authorAvatarUrl != null
                  ? Image.network(post.authorAvatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Symbols.person, size: 20,
                          color: AppTheme.onSurfaceVariant))
                  : const Icon(Symbols.person, size: 20,
                      color: AppTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post.authorName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: post.authorIsStaff
                            ? AppTheme.primaryContainer
                            : AppTheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                    if (post.authorIsStaff) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                              color: AppTheme.primaryContainer.withOpacity(0.3)),
                        ),
                        child: Text('STAFF',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontSize: 9,
                          )),
                      ),
                    ],
                  ],
                ),
                Text(post.timeAgo,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          // Kebab — flag action
          GestureDetector(
            onTap: () {}, // handled by footer's flag button
            child: const Icon(Symbols.more_horiz,
                size: 20, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Full-bleed image ──────────────────────────────────────────────────────────
class _PostImage extends StatelessWidget {
  final FeedPost post;
  const _PostImage({required this.post});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(post.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.surfaceContainerLowest,
                child: const Center(child: Icon(Symbols.image, size: 40,
                    color: AppTheme.onSurfaceVariant)),
              )),
          Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.photoScrim)),
          ),
          Positioned(
            left: AppTheme.gutter,
            right: AppTheme.gutter,
            bottom: AppTheme.gutter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(post.content,
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(color: AppTheme.onSurface),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.stackSm),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: post.tags.map((t) => _InlineTag(
                      label: t,
                      isHighlighted: t.contains('PR') || t.contains('KG'),
                    )).toList()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag chips ────────────────────────────────────────────────────────────────
class _TagChipRow extends StatelessWidget {
  final List<String> tags;
  const _TagChipRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter, 0, AppTheme.gutter, AppTheme.stackSm),
      child: Row(
        children: tags.map((t) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _InlineTag(label: t,
              isHighlighted: t.contains('PR') || t.contains('KG')),
        )).toList(),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String label;
  final bool isHighlighted;
  const _InlineTag({required this.label, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.surfaceContainer.withOpacity(0.85)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.primaryContainer.withOpacity(0.25)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isHighlighted
              ? AppTheme.primaryContainer
              : AppTheme.onSurfaceVariant,
        )),
    );
  }
}

// ─── Post footer ──────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: AppTheme.stackSm),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withOpacity(0.5),
        border: Border(top: BorderSide(
            color: Colors.white.withOpacity(0.07), width: 1)),
      ),
      child: Row(
        children: [
          // Like
          GestureDetector(
            onTap: onLikeTap,
            child: Row(children: [
              Icon(Symbols.favorite, size: 18,
                color: post.isLiked
                    ? AppTheme.primaryContainer
                    : AppTheme.onSurfaceVariant,
                fill: post.isLiked ? 1.0 : 0.0),
              const SizedBox(width: 5),
              Text('${post.likeCount}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: post.isLiked
                      ? AppTheme.primaryContainer
                      : AppTheme.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: AppTheme.stackMd),
          // Comment
          GestureDetector(
            onTap: onCommentTap,
            child: Row(children: [
              const Icon(Symbols.chat_bubble, size: 18,
                  color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Text('${post.commentCount}',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppTheme.onSurfaceVariant)),
            ]),
          ),
          const Spacer(),
          // Flag
          GestureDetector(
            onTap: onFlagTap,
            child: const Icon(Symbols.flag, size: 18,
                color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff FAB — only visible when user has isStaff flag
// Falls back gracefully when SKIP_LOGIN mode (no auth context)
// ─────────────────────────────────────────────────────────────────────────────
class _StaffFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: read isStaff from auth provider once OTP auth is wired
    // For now show FAB only — it will fail with 403 when non-staff tries to post
    return FloatingActionButton(
      onPressed: () => CreatePostSheet.show(context,
        onPostCreated: (post) =>
            ref.read(feedProvider.notifier).prependPost(post)),
      backgroundColor: AppTheme.primaryContainer,
      foregroundColor: AppTheme.onPrimaryFixed,
      child: const Icon(Symbols.edit, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _SocialAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64 + topPadding,
          padding: EdgeInsets.only(
            top: topPadding,
            left: AppTheme.gutter,
            right: AppTheme.gutter,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: Center(
                  child: Text('TETHER',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryContainer,
                      letterSpacing: 0.06 * 28,
                      shadows: [Shadow(
                        color: AppTheme.primaryContainer.withOpacity(0.25),
                        blurRadius: 16)],
                    )),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceContainerHigh,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: const Icon(Symbols.notifications,
                      size: 18, color: AppTheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
