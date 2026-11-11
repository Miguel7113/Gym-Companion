import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/pr_ranking.dart';
import '../services/personal_records_service.dart';
import 'gender_filter_toggle.dart';
import 'leaderboard_modal.dart';

/// Main PR showcase widget for profile screens
/// Displays top 3 + user position for Bench/Squat/Deadlift
class PRShowcaseWidget extends ConsumerStatefulWidget {
  final String userId; // User whose PRs to display
  final String gymId;
  final bool showGenderFilter; // Whether to show the gender filter toggle

  const PRShowcaseWidget({
    super.key,
    required this.userId,
    required this.gymId,
    this.showGenderFilter = true, // Default to true for backwards compatibility
  });

  @override
  ConsumerState<PRShowcaseWidget> createState() => _PRShowcaseWidgetState();
}

class _PRShowcaseWidgetState extends ConsumerState<PRShowcaseWidget> {
  String? _selectedGender; // null = 'all', 'male', 'female'

  @override
  Widget build(BuildContext context) {
    // For profile views, force gender filter to null (no filtering)
    final effectiveGenderFilter = widget.showGenderFilter ? _selectedGender : null;
    
    final params = PRShowcaseParams(
      userId: widget.userId,
      gymId: widget.gymId,
      genderFilter: effectiveGenderFilter,
    );

    final showcaseAsync = ref.watch(prShowcaseProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Text(
              'Personal Records',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
            const Spacer(),
            // Refresh button
            IconButton(
              onPressed: () {
                ref.invalidate(prShowcaseProvider(params));
              },
              icon: const Icon(
                Symbols.refresh,
                size: 20,
                color: AppTheme.onSurfaceVariant,
              ),
              tooltip: 'Refresh',
            ),
          ],
        ),

        const SizedBox(height: AppTheme.stackSm),

        // Gender Filter (only show if enabled)
        if (widget.showGenderFilter) ...[
          GenderFilterToggle(
            selectedGender: _selectedGender,
            onChanged: (gender) {
              setState(() => _selectedGender = gender);
            },
          ),
          const SizedBox(height: AppTheme.stackMd),
        ],

        // Content
        showcaseAsync.when(
          loading: () => const _LoadingSkeleton(),
          error: (error, stack) => _ErrorState(
            message: 'Failed to load personal records',
            onRetry: () => ref.invalidate(prShowcaseProvider(params)),
          ),
          data: (showcaseData) {
            if (!showcaseData.hasAnyRanking) {
              return _EmptyState(
                userId: widget.userId,
                currentUserId: ref.watch(currentUserProvider)?.memberId,
              );
            }

            return Column(
              children: [
                _ExerciseCard(
                  leaderboard: showcaseData.benchPress,
                  onTap: () => _showLeaderboardModal(
                    context,
                    showcaseData.benchPress,
                  ),
                ),
                const SizedBox(height: 12),
                _ExerciseCard(
                  leaderboard: showcaseData.squat,
                  onTap: () => _showLeaderboardModal(
                    context,
                    showcaseData.squat,
                  ),
                ),
                const SizedBox(height: 12),
                _ExerciseCard(
                  leaderboard: showcaseData.deadlift,
                  onTap: () => _showLeaderboardModal(
                    context,
                    showcaseData.deadlift,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLeaderboardModal(BuildContext context, PRLeaderboard leaderboard) {
    LeaderboardModal.show(
      context,
      exerciseName: leaderboard.exerciseName,
      gymId: widget.gymId,
      genderFilter: widget.showGenderFilter ? _selectedGender : null,
    );
  }
}

/// Individual exercise card showing podium + user rank
class _ExerciseCard extends StatelessWidget {
  final PRLeaderboard leaderboard;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.leaderboard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getExerciseColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Icon(
                    _getExerciseIcon(),
                    size: 20,
                    color: _getExerciseColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaderboard.exerciseName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        leaderboard.totalRankedText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Podium or Empty State
            if (leaderboard.topThree.isEmpty)
              _NoPRsYet(exerciseName: leaderboard.shortName)
            else
              _PodiumView(rankings: leaderboard.topThree),

            // User's Position (if not in top 3)
            if (leaderboard.currentUserRanking != null &&
                !leaderboard.isUserOnPodium) ...[
              const SizedBox(height: 12),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
              ),
              const SizedBox(height: 12),
              _UserRankCard(ranking: leaderboard.currentUserRanking!),
            ],

            // "Not Ranked" message if user has no PR
            if (leaderboard.currentUserRanking == null) ...[
              const SizedBox(height: 12),
              _NotRankedCard(exerciseName: leaderboard.shortName),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getExerciseIcon() {
    switch (leaderboard.exerciseName.toLowerCase()) {
      case 'bench press':
        return Symbols.fitness_center;
      case 'squat':
        return Symbols.airline_seat_legroom_normal;
      case 'deadlift':
        return Symbols.exercise;
      default:
        return Symbols.fitness_center;
    }
  }

  Color _getExerciseColor() {
    switch (leaderboard.exerciseName.toLowerCase()) {
      case 'bench press':
        return const Color(0xFF6366F1); // Indigo
      case 'squat':
        return const Color(0xFFEC4899); // Pink
      case 'deadlift':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppTheme.primaryContainer;
    }
  }
}

/// Podium display showing top 3 rankings
class _PodiumView extends StatelessWidget {
  final List<PRRanking> rankings;

  const _PodiumView({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least 1, pad with nulls if needed
    final first = rankings.isNotEmpty ? rankings[0] : null;
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 2nd Place
        if (second != null)
          Expanded(child: _PodiumPosition(ranking: second))
        else
          const Expanded(child: SizedBox()),

        const SizedBox(width: 8),

        // 1st Place (taller)
        if (first != null)
          Expanded(child: _PodiumPosition(ranking: first, isFirst: true))
        else
          const Expanded(child: SizedBox()),

        const SizedBox(width: 8),

        // 3rd Place
        if (third != null)
          Expanded(child: _PodiumPosition(ranking: third))
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }
}

/// Single podium position (🥇🥈🥉)
class _PodiumPosition extends StatelessWidget {
  final PRRanking ranking;
  final bool isFirst;

  const _PodiumPosition({
    required this.ranking,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isFirst ? 110.0 : 90.0;

    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ranking.isCurrentUser
            ? AppTheme.primaryContainer.withValues(alpha: 0.2)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: ranking.isCurrentUser
            ? Border.all(
                color: AppTheme.primaryContainer,
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Medal
          Text(
            ranking.medalEmoji ?? '',
            style: const TextStyle(fontSize: 24),
          ),

          const SizedBox(height: 4),

          // Avatar or Initials
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: ranking.avatarPath != null
                ? AppCachedImage(
                    url: ranking.avatarPath!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      _getInitials(ranking.displayName),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
          ),

          const SizedBox(height: 4),

          // Name
          Text(
            ranking.isCurrentUser ? 'You' : ranking.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight:
                      ranking.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                  color: ranking.isCurrentUser
                      ? AppTheme.primaryContainer
                      : AppTheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 2),

          // PR Value
          Text(
            ranking.displayText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 10,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// User's rank card (when not in top 3)
class _UserRankCard extends StatelessWidget {
  final PRRanking ranking;

  const _UserRankCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${ranking.rank}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Position',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  ranking.displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Not Ranked" message
class _NotRankedCard extends StatelessWidget {
  final String exerciseName;

  const _NotRankedCard({required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.info,
            size: 18,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not ranked yet - submit a verified $exerciseName PR to compete',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no PRs exist
class _NoPRsYet extends StatelessWidget {
  final String exerciseName;

  const _NoPRsYet({required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        'No verified PRs yet',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Loading skeleton
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonBox(
          width: double.infinity,
          height: 180,
          radius: AppTheme.radiusXxl,
        ),
        const SizedBox(height: 12),
        SkeletonBox(
          width: double.infinity,
          height: 180,
          radius: AppTheme.radiusXxl,
        ),
        const SizedBox(height: 12),
        SkeletonBox(
          width: double.infinity,
          height: 180,
          radius: AppTheme.radiusXxl,
        ),
      ],
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.cloud_off,
            size: 48,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Symbols.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Empty state when user has no verified PRs
class _EmptyState extends StatelessWidget {
  final String userId;
  final String? currentUserId;

  const _EmptyState({
    required this.userId,
    required this.currentUserId,
  });

  bool get isOwnProfile => userId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.emoji_events,
            size: 48,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isOwnProfile
                ? 'No Personal Records Yet'
                : 'No Verified PRs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isOwnProfile
                ? 'Submit your best lifts in Bench Press, Squat, and Deadlift to compete on the leaderboards'
                : 'This member hasn\'t submitted any verified personal records yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
