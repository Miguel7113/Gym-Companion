import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'workout_builder_screen.dart';
import 'workout_session_screen.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? routine;
  final WorkoutSession? session;

  const WorkoutDetailScreen({super.key, this.routine, this.session})
      : assert(routine != null || session != null);

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  List<WorkoutSession> _history = [];
  RoutineLeaderboard? _leaderboard;
  String? _selectedExerciseId;
  String _metric = 'volume';
  bool _loadingHistory = false;
  bool _loadingLeaderboard = false;
  String? _historyError;
  String? _leaderboardError;

  WorkoutTemplate? get _routine => widget.routine;
  List<WorkoutTemplateExercise> get _plannedExercises =>
      _routine?.exercises ?? const [];

  @override
  void initState() {
    super.initState();
    if (_routine != null && _plannedExercises.isNotEmpty) {
      _selectedExerciseId = _plannedExercises.first.exerciseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHistory();
        _loadLeaderboard();
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_routine == null || _loadingHistory) return;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history =
          await ref.read(workoutServiceProvider).getRoutineHistory(_routine!.id);
      if (mounted) setState(() => _history = history);
    } catch (e) {
      if (mounted) setState(() => _historyError = 'History is unavailable right now.');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_routine == null || _selectedExerciseId == null || _loadingLeaderboard) {
      return;
    }
    setState(() {
      _loadingLeaderboard = true;
      _leaderboardError = null;
    });
    try {
      final leaderboard =
          await ref.read(workoutServiceProvider).getRoutineLeaderboard(
                routineId: _routine!.id,
                exerciseId: _selectedExerciseId!,
                metric: _metric,
              );
      if (mounted) setState(() => _leaderboard = leaderboard);
    } catch (e) {
      if (mounted) {
        setState(() => _leaderboardError =
            'Certified leaderboard results are unavailable right now.');
      }
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  String _duration(WorkoutSession session) {
    final end = session.endedAt;
    if (end == null) return 'In progress';
    final duration = end.difference(session.startedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final routine = _routine;
    final session = widget.session;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(routine?.name ?? session?.notes ?? 'Workout'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (session != null && session.endedAt != null)
            IconButton(
              onPressed: () {
                final ended = session.endedAt!;
                final duration = ended.difference(session.startedAt);
                final exerciseIds =
                    session.sets.map((s) => s.exerciseId).toSet();
                final volume = session.sets.fold<double>(
                  0,
                  (sum, set) =>
                      sum + (set.weightKg ?? 0) * (set.reps ?? 0),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutCompleteScreen(
                      sessionId: session.id,
                      duration: duration,
                      totalSets: session.sets.length,
                      exerciseCount: exerciseIds.length,
                      prCount: 0,
                      totalVolume: volume,
                      workoutName: session.notes,
                    ),
                  ),
                );
              },
              icon: const Icon(Symbols.ios_share),
              tooltip: 'Share to feed',
            ),
          if (routine != null)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutBuilderScreen(routine: routine),
                ),
              ),
              icon: const Icon(Symbols.play_arrow),
              tooltip: 'Start routine',
            ),
        ],
      ),
      body: routine != null
          ? DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  _RoutineHeader(routine: routine, onStart: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutBuilderScreen(routine: routine),
                      ),
                    );
                  }),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'SUMMARY'),
                      Tab(text: 'HISTORY'),
                      Tab(text: 'LEADERBOARD'),
                      Tab(text: 'How to'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _SummaryTab(routine: routine),
                        _HistoryTab(
                          history: _history,
                          loading: _loadingHistory,
                          error: _historyError,
                          onLoad: _loadHistory,
                          duration: _duration,
                        ),
                        _LeaderboardTab(
                          routine: routine,
                          selectedExerciseId: _selectedExerciseId,
                          metric: _metric,
                          leaderboard: _leaderboard,
                          loading: _loadingLeaderboard,
                          error: _leaderboardError,
                          onExerciseChanged: (id) {
                            setState(() {
                              _selectedExerciseId = id;
                              _leaderboard = null;
                            });
                            _loadLeaderboard();
                          },
                          onMetricChanged: (metric) {
                            setState(() {
                              _metric = metric;
                              _leaderboard = null;
                            });
                            _loadLeaderboard();
                          },
                          onLoad: _loadLeaderboard,
                        ),
                        _HowToTab(
                          exercises: routine.exercises
                              .map((planned) => planned.exercise)
                              .whereType<Exercise>()
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _ManualSessionDetail(session: session!),
    );
  }
}

class _RoutineHeader extends StatelessWidget {
  final WorkoutTemplate routine;
  final VoidCallback onStart;

  const _RoutineHeader({required this.routine, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.containerMargin,
        AppTheme.stackSm,
        AppTheme.containerMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (routine.description?.isNotEmpty == true)
            Text(
              routine.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          const SizedBox(height: AppTheme.stackSm),
          Row(
            children: [
              Icon(Symbols.fitness_center,
                  size: 18, color: AppTheme.primaryContainer),
              const SizedBox(width: 6),
              Text('${routine.exercises.length} exercises'),
              if (routine.durationMins != null) ...[
                const SizedBox(width: 14),
                Icon(Symbols.timer,
                    size: 18, color: AppTheme.primaryContainer),
                const SizedBox(width: 6),
                Text('${routine.durationMins} min'),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Symbols.play_arrow, size: 18),
                label: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final WorkoutTemplate routine;
  const _SummaryTab({required this.routine});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      children: [
        Text('Planned exercises',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTheme.stackSm),
        ...routine.exercises.map(
          (planned) => GlassCard(
            margin: const EdgeInsets.only(bottom: AppTheme.stackSm),
            padding: const EdgeInsets.all(AppTheme.stackMd),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryContainer.withOpacity(.12),
                  child: Text('${planned.sortOrder + 1}',
                      style: const TextStyle(color: AppTheme.primaryContainer)),
                ),
                const SizedBox(width: AppTheme.stackSm),
                Expanded(
                  child: Text(
                    planned.exercise?.name ?? 'Exercise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  [
                    if (planned.defaultSets != null)
                      '${planned.defaultSets} sets',
                    if (planned.defaultReps != null)
                      '${planned.defaultReps} reps',
                  ].join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<WorkoutSession> history;
  final bool loading;
  final String? error;
  final Future<void> Function() onLoad;
  final String Function(WorkoutSession) duration;

  const _HistoryTab({
    required this.history,
    required this.loading,
    required this.error,
    required this.onLoad,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return _DetailMessage(message: error!, action: () => onLoad());
    }
    if (history.isEmpty) {
      return _DetailMessage(
        message: 'Your completed runs will appear here.',
        action: () => onLoad(),
        actionLabel: 'Load history',
      );
    }
    return RefreshIndicator(
      onRefresh: onLoad,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.containerMargin),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.stackSm),
        itemBuilder: (_, index) {
          final session = history[index];
          return GlassCard(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            child: Row(
              children: [
                const Icon(Symbols.calendar_month,
                    color: AppTheme.primaryContainer),
                const SizedBox(width: AppTheme.stackSm),
                Expanded(
                  child: Text(
                    '${session.startedAt.day}/${session.startedAt.month}/${session.startedAt.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${session.sets.length} sets · ${duration(session)}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final WorkoutTemplate routine;
  final String? selectedExerciseId;
  final String metric;
  final RoutineLeaderboard? leaderboard;
  final bool loading;
  final String? error;
  final ValueChanged<String> onExerciseChanged;
  final ValueChanged<String> onMetricChanged;
  final Future<void> Function() onLoad;

  const _LeaderboardTab({
    required this.routine,
    required this.selectedExerciseId,
    required this.metric,
    required this.leaderboard,
    required this.loading,
    required this.error,
    required this.onExerciseChanged,
    required this.onMetricChanged,
    required this.onLoad,
  });

  String _metricLabel(String value) =>
      value == 'weight' ? 'Heaviest' : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    if (routine.exercises.isEmpty) {
      return const _DetailMessage(message: 'Add exercises to see rankings.');
    }
    return ListView(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      children: [
        DropdownButtonFormField<String>(
          value: selectedExerciseId,
          decoration: const InputDecoration(labelText: 'EXERCISE'),
          items: routine.exercises
              .map((planned) => DropdownMenuItem(
                    value: planned.exerciseId,
                    child: Text(planned.exercise?.name ?? 'Exercise'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onExerciseChanged(value);
          },
        ),
        const SizedBox(height: AppTheme.stackSm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'volume', label: Text('VOLUME')),
            ButtonSegment(value: 'weight', label: Text('WEIGHT')),
            ButtonSegment(value: 'reps', label: Text('REPS')),
          ],
          selected: {metric},
          onSelectionChanged: (selection) =>
              onMetricChanged(selection.first),
        ),
        const SizedBox(height: AppTheme.stackMd),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          _DetailMessage(message: error!, action: () => onLoad())
        else if (leaderboard == null)
          _DetailMessage(
            message: 'Only workouts certified by a coach appear here.',
            action: () => onLoad(),
            actionLabel: 'View certified results',
          )
        else if (leaderboard!.entries.isEmpty)
          const _DetailMessage(
            message: 'No certified results for this exercise yet.',
          )
        else
          ...leaderboard!.entries.asMap().entries.map(
                (item) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.key == 0
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerHigh,
                    child: Text('${item.key + 1}'),
                  ),
                  title: Text(item.value.displayName),
                  subtitle: Text('Certified by ${item.value.coachName}'),
                  trailing: Text(
                    '${item.value.value.toStringAsFixed(metric == 'reps' ? 0 : 1)} ${_metricLabel(metric)}',
                  ),
                ),
              ),
      ],
    );
  }
}

class _HowToTab extends StatelessWidget {
  final List<Exercise> exercises;
  const _HowToTab({required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const _DetailMessage(
        message: 'Exercise instructions will appear when exercise details are available.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.stackSm),
      itemBuilder: (_, index) {
        final exercise = exercises[index];
        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(exercise.name),
          subtitle: Text(exercise.overview ?? 'Technique and movement guidance'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (exercise.instructions.isNotEmpty)
              ...exercise.instructions.asMap().entries.map(
                    (instruction) => Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${instruction.key + 1}. ${instruction.value}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No instructions have been added yet.'),
              ),
          ],
        );
      },
    );
  }
}

class _ManualSessionDetail extends StatelessWidget {
  final WorkoutSession session;
  const _ManualSessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final duration = session.endedAt == null
        ? 'In progress'
        : '${session.endedAt!.difference(session.startedAt).inMinutes} min';

    final byExercise = <String, List<WorkoutSet>>{};
    final exerciseMeta = <String, Exercise>{};
    for (final set in session.sets) {
      byExercise.putIfAbsent(set.exerciseId, () => []).add(set);
      if (set.exercise != null) {
        exerciseMeta[set.exerciseId] = set.exercise!;
      }
    }
    final exerciseIds = byExercise.keys.toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.containerMargin),
      children: [
        _SummaryStats(
          duration: duration,
          sets: session.sets.length,
          exercises: exerciseIds.length,
        ),
        const SizedBox(height: AppTheme.stackLg),
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.stackSm),
        if (exerciseIds.isEmpty)
          const _DetailMessage(
            message:
                'No sets were logged for this workout. Next time, tap ✓ on each set (or Finish will save filled rows).',
          )
        else
          ...exerciseIds.map((exerciseId) {
            final sets = byExercise[exerciseId]!;
            final name = exerciseMeta[exerciseId]?.name ?? 'Exercise';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.stackSm),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTheme.stackSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...sets.map(
                      (set) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Set ${set.setNumber ?? '?'}  ·  ${set.weightKg ?? 0} kg × ${set.reps ?? 0}'
                          '${set.rpe != null ? '  ·  RPE ${set.rpe}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final String duration;
  final int sets;
  final int exercises;
  const _SummaryStats({
    required this.duration,
    required this.sets,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Duration', value: duration)),
        const SizedBox(width: AppTheme.stackSm),
        Expanded(child: _Stat(label: 'SETS', value: '$sets')),
        const SizedBox(width: AppTheme.stackSm),
        Expanded(child: _Stat(label: 'Exercises', value: '$exercises')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.stackSm),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  final String message;
  final VoidCallback? action;
  final String actionLabel;

  const _DetailMessage({
    required this.message,
    this.action,
    this.actionLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.containerMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: AppTheme.stackSm),
              OutlinedButton(onPressed: action, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
