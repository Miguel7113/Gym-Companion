import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'exercise_thumbnail.dart';

/// Bottom sheet with exercise education, personal history, and optional
/// routine leaderboard — opened when tapping an exercise name mid-session.
class ExerciseInfoSheet extends ConsumerStatefulWidget {
  final Exercise exercise;
  final String? routineId;

  const ExerciseInfoSheet({
    super.key,
    required this.exercise,
    this.routineId,
  });

  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    String? routineId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ExerciseInfoSheet(
          exercise: exercise,
          routineId: routineId,
        ),
      ),
    );
  }

  @override
  ConsumerState<ExerciseInfoSheet> createState() => _ExerciseInfoSheetState();
}

class _ExerciseInfoSheetState extends ConsumerState<ExerciseInfoSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<ProgressData> _history = [];
  RoutineLeaderboard? _leaderboard;
  bool _loadingHistory = true;
  bool _loadingLeaderboard = false;
  String? _historyError;
  String? _leaderboardError;
  String _metric = 'volume';

  @override
  void initState() {
    super.initState();
    final tabCount = widget.routineId != null ? 3 : 2;
    _tabs = TabController(length: tabCount, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == tabCount - 1 &&
          widget.routineId != null &&
          _leaderboard == null &&
          !_loadingLeaderboard) {
        _loadLeaderboard();
      }
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history =
          await ref.read(workoutServiceProvider).getProgress(widget.exercise.id);
      if (mounted) setState(() => _history = history);
    } catch (_) {
      if (mounted) {
        setState(() => _historyError = 'History is unavailable right now.');
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    final routineId = widget.routineId;
    if (routineId == null) return;
    setState(() {
      _loadingLeaderboard = true;
      _leaderboardError = null;
    });
    try {
      final board = await ref.read(workoutServiceProvider).getRoutineLeaderboard(
            routineId: routineId,
            exerciseId: widget.exercise.id,
            metric: _metric,
          );
      if (mounted) setState(() => _leaderboard = board);
    } catch (_) {
      if (mounted) {
        setState(
          () => _leaderboardError =
              'Certified leaderboard results are unavailable right now.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final hasLeaderboard = widget.routineId != null;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              ExerciseThumbnail(exercise: ex, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ex.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryContainer,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Symbols.close),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primaryContainer,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          indicatorColor: AppTheme.primaryContainer,
          tabs: [
            const Tab(text: 'How To'),
            const Tab(text: 'History'),
            if (hasLeaderboard) const Tab(text: 'Leaderboard'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _HowToTab(exercise: ex),
              _HistoryTab(
                loading: _loadingHistory,
                error: _historyError,
                history: _history,
                onRetry: _loadHistory,
              ),
              if (hasLeaderboard)
                _LeaderboardTab(
                  loading: _loadingLeaderboard,
                  error: _leaderboardError,
                  leaderboard: _leaderboard,
                  metric: _metric,
                  onMetricChanged: (metric) {
                    setState(() {
                      _metric = metric;
                      _leaderboard = null;
                    });
                    _loadLeaderboard();
                  },
                  onRetry: _loadLeaderboard,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowToTab extends StatelessWidget {
  final Exercise exercise;

  const _HowToTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      children: [
        if (exercise.gifUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: AppCachedImage(url: exercise.gifUrl, fit: BoxFit.cover),
            ),
          ),
        if (exercise.overview?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            exercise.overview!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.55,
                ),
          ),
        ],
        if (exercise.targetMuscles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'PRIMARY MUSCLES',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercise.targetMuscles
                .map(
                  (m) => Chip(
                    label: Text(m.toUpperCase()),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                )
                .toList(),
          ),
        ],
        if (exercise.instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'INSTRUCTIONS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...exercise.instructions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppTheme.primaryContainer.withOpacity(0.15),
                        child: Text(
                          '${entry.key + 1}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryContainer,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value.replaceFirst(RegExp(r'^Step:\d+\s*'), ''),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<ProgressData> history;
  final VoidCallback onRetry;

  const _HistoryTab({
    required this.loading,
    required this.error,
    required this.history,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: Theme.of(context).textTheme.bodyMedium),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (history.isEmpty) {
      return Center(
        child: Text(
          'No previous sets logged for this exercise.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = history[history.length - 1 - i];
        final date = item.date;
        final label = '${date.day}/${date.month}/${date.year}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          trailing: Text(
            '${item.weightKg?.toStringAsFixed(0) ?? 0} kg × ${item.reps ?? 0}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final RoutineLeaderboard? leaderboard;
  final String metric;
  final ValueChanged<String> onMetricChanged;
  final VoidCallback onRetry;

  const _LeaderboardTab({
    required this.loading,
    required this.error,
    required this.leaderboard,
    required this.metric,
    required this.onMetricChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'volume', label: Text('Volume')),
              ButtonSegment(value: 'weight', label: Text('Weight')),
              ButtonSegment(value: 'reps', label: Text('Reps')),
            ],
            selected: {metric},
            onSelectionChanged: (values) => onMetricChanged(values.first),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!),
                          TextButton(onPressed: onRetry, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : leaderboard == null || leaderboard!.entries.isEmpty
                      ? Center(
                          child: Text(
                            'No coach-certified results yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: leaderboard!.entries.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final entry = leaderboard!.entries[i];
                            final valueLabel = leaderboard!.metric == 'reps'
                                ? '${entry.value.toStringAsFixed(0)} reps'
                                : '${entry.value.toStringAsFixed(1)} kg';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(entry.displayName),
                              subtitle: Text(
                                'Certified by ${entry.coachName}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              trailing: Text(
                                valueLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
