import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/personal_record.dart';
import '../services/personal_records_service.dart';
import 'gender_filter_toggle.dart';

/// Full leaderboard modal for a specific exercise
/// Shows all rankings with scrolling, filtering, and search
class LeaderboardModal extends ConsumerStatefulWidget {
  final String exerciseName; // 'Bench Press', 'Squat', or 'Deadlift'
  final String gymId;
  final String? initialGenderFilter;

  const LeaderboardModal({
    super.key,
    required this.exerciseName,
    required this.gymId,
    this.initialGenderFilter,
  });

  @override
  ConsumerState<LeaderboardModal> createState() => _LeaderboardModalState();

  /// Show the modal
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required String gymId,
    String? genderFilter,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LeaderboardModal(
        exerciseName: exerciseName,
        gymId: gymId,
        initialGenderFilter: genderFilter,
      ),
    );
  }
}

class _LeaderboardModalState extends ConsumerState<LeaderboardModal> {
  String? _selectedGender;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGenderFilter;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXxl),
          topRight: Radius.circular(AppTheme.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Exercise Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getExerciseColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getExerciseIcon(),
                        size: 24,
                        color: _getExerciseColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.exerciseName} Leaderboard',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            'Top lifters at your gym',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Symbols.close,
                        size: 24,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Gender Filter
                Align(
                  alignment: Alignment.centerLeft,
                  child: GenderFilterToggleCompact(
                    selectedGender: _selectedGender,
                    onChanged: (gender) {
                      setState(() => _selectedGender = gender);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Leaderboard List
          Expanded(
            child: _LeaderboardList(
              exerciseName: widget.exerciseName,
              gymId: widget.gymId,
              genderFilter: _selectedGender,
              currentUserId: currentUser?.memberId,
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon() {
    switch (widget.exerciseName.toLowerCase()) {
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
    switch (widget.exerciseName.toLowerCase()) {
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

/// Scrollable leaderboard list
class _LeaderboardList extends ConsumerWidget {
  final String exerciseName;
  final String gymId;
  final String? genderFilter;
  final String? currentUserId;
  final ScrollController scrollController;

  const _LeaderboardList({
    required this.exerciseName,
    required this.gymId,
    required this.genderFilter,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(personalRecordsServiceProvider);
    final session = ref.watch(currentSessionProvider);

    if (session?.accessToken == null) {
      return const _ErrorMessage(message: 'Not authenticated');
    }

    return FutureBuilder<List<LeaderboardEntry>>(
      future: service.getLeaderboard(
        gymId: gymId,
        exercise: exerciseName,
        gender: genderFilter,
        limit: 100, // Show top 100
        token: session!.accessToken,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snapshot.hasError) {
          return _ErrorMessage(
            message: 'Failed to load leaderboard',
            error: snapshot.error.toString(),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return _EmptyState(
            exerciseName: exerciseName,
            genderFilter: genderFilter,
          );
        }

        // Find current user's position
        final userIndex = currentUserId != null
            ? entries.indexWhere((e) => e.userId == currentUserId)
            : -1;

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            final isCurrentUser = entry.userId == currentUserId;

            // Scroll to user on first build
            if (isCurrentUser && userIndex > 3) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  scrollController.animateTo(
                    (userIndex * 80.0) - 100,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return _LeaderboardRow(
              rank: rank,
              entry: entry,
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }
}

/// Individual leaderboard row
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isPodium = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryContainer.withValues(alpha: 0.15)
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: isCurrentUser
            ? Border.all(
                color: AppTheme.primaryContainer,
                width: 2,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPodium
                  ? _getRankColor()
                  : AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isPodium
                ? Text(
                    _getMedalEmoji(),
                    style: const TextStyle(fontSize: 20),
                  )
                : Text(
                    '#$rank',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isCurrentUser
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                  ),
          ),

          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: entry.user.avatarPath != null
                ? AppCachedImage(
                    url: entry.user.avatarPath!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      _getInitials(entry.user.displayName ?? 'Member'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Name and PR
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isCurrentUser
                            ? 'You'
                            : entry.user.displayName ?? 'Member',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: isCurrentUser
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isCurrentUser
                                  ? AppTheme.primaryContainer
                                  : AppTheme.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.user.gender != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        entry.user.gender == 'male'
                            ? Icons.male
                            : Icons.female,
                        size: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Verified Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.toneSuccess.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.verified,
                  size: 12,
                  color: AppTheme.toneSuccess,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.toneSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMedalEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700).withValues(alpha: 0.2); // Gold
      case 2:
        return const Color(0xFFC0C0C0).withValues(alpha: 0.2); // Silver
      case 3:
        return const Color(0xFFCD7F32).withValues(alpha: 0.2); // Bronze
      default:
        return AppTheme.surfaceContainerHigh;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Loading state
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SkeletonBox(
            width: double.infinity,
            height: 64,
            radius: AppTheme.radiusLg,
          ),
        );
      },
    );
  }
}

/// Error message
class _ErrorMessage extends StatelessWidget {
  final String message;
  final String? error;

  const _ErrorMessage({
    required this.message,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.cloud_off,
              size: 64,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  final String exerciseName;
  final String? genderFilter;

  const _EmptyState({
    required this.exerciseName,
    this.genderFilter,
  });

  @override
  Widget build(BuildContext context) {
    final filterText = genderFilter != null && genderFilter != 'all'
        ? ' for ${genderFilter}s'
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.emoji_events,
              size: 64,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rankings Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No verified $exerciseName PRs$filterText at your gym',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Be the first to submit!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
