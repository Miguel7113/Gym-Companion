import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../models/coach_stats.dart';

/// Dashboard header showing coach statistics
/// Displays pending count, verified today, and avg response time
class CoachStatsHeader extends StatelessWidget {
  final CoachStats? stats;
  final VoidCallback? onRefresh;

  const CoachStatsHeader({
    super.key,
    required this.stats,
    this.onRefresh,
  });

  bool get _isLoading => stats == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and refresh
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Symbols.workspace_premium,
                  size: 20,
                  color: AppTheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Dashboard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'PR Verification',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(
                    Symbols.refresh,
                    size: 20,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  tooltip: 'Refresh',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: _isLoading ? '-' : '${stats!.pendingCount}',
                  icon: Symbols.pending_actions,
                  color: _isLoading
                      ? AppTheme.onSurfaceVariant
                      : (stats!.pendingCount > 0
                          ? AppTheme.toneWarning
                          : AppTheme.onSurfaceVariant),
                  subtitle: _isLoading
                      ? 'loading'
                      : (stats!.pendingCount == 1 ? 'PR to review' : 'PRs to review'),
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Verified Today',
                  value: _isLoading ? '-' : '${stats!.verifiedToday}',
                  icon: Symbols.check_circle,
                  color: AppTheme.toneSuccess,
                  subtitle: 'approved',
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg Time',
                  value: _isLoading ? '-' : _formatResponseTime(stats!.avgResponseTimeHours),
                  icon: Symbols.schedule,
                  color: _isLoading
                      ? AppTheme.onSurfaceVariant
                      : _getTimeColor(stats!.avgResponseTimeHours),
                  subtitle: 'response',
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),

          // Exercise breakdown (if any pending)
          if (!_isLoading &&
              stats!.pendingCount > 0 &&
              _hasExercises(stats!.byExercise)) ...[
            const SizedBox(height: 16),
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: 16),
            _ExerciseBreakdown(byExercise: stats!.byExercise),
          ],
        ],
      ),
    );
  }

  bool _hasExercises(ExerciseBreakdown breakdown) {
    return breakdown.benchPress > 0 ||
        breakdown.squat > 0 ||
        breakdown.deadlift > 0;
  }

  String _formatResponseTime(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      final days = (hours / 24).round();
      return '${days}d';
    }
  }

  Color _getTimeColor(double hours) {
    if (hours < 2) return AppTheme.toneSuccess; // Fast: green
    if (hours < 6) return AppTheme.primaryContainer; // Good: yellow
    if (hours < 24) return AppTheme.toneWarning; // Slow: orange
    return AppTheme.toneDanger; // Very slow: red
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isLoading;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Exercise breakdown section
class _ExerciseBreakdown extends StatelessWidget {
  final ExerciseBreakdown byExercise;

  const _ExerciseBreakdown({required this.byExercise});

  @override
  Widget build(BuildContext context) {
    final exercises = <MapEntry<String, int>>[];
    
    if (byExercise.benchPress > 0) {
      exercises.add(const MapEntry('Bench Press', 0));
      exercises[exercises.length - 1] = MapEntry('Bench Press', byExercise.benchPress);
    }
    if (byExercise.squat > 0) {
      exercises.add(MapEntry('Squat', byExercise.squat));
    }
    if (byExercise.deadlift > 0) {
      exercises.add(MapEntry('Deadlift', byExercise.deadlift));
    }
    
    exercises.sort((a, b) => b.value.compareTo(a.value)); // Sort by count DESC

    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Exercise',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...exercises.map((entry) => _ExerciseRow(
              exercise: entry.key,
              count: entry.value,
            )),
      ],
    );
  }
}

/// Individual exercise row in breakdown
class _ExerciseRow extends StatelessWidget {
  final String exercise;
  final int count;

  const _ExerciseRow({
    required this.exercise,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            _getExerciseIcon(),
            size: 16,
            color: _getExerciseColor(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exercise,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurface,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getExerciseColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getExerciseColor(),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon() {
    switch (exercise.toLowerCase()) {
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
    switch (exercise.toLowerCase()) {
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
