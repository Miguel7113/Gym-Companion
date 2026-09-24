import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/sync/connectivity_provider.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import 'exercise_picker_sheet.dart';
import '../widgets/exercise_info_sheet.dart';
import '../widgets/exercise_thumbnail.dart';
import 'workout_session_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutBuilderScreen
//
// Users plan their workout before starting the session timer.
// Exercises are added from ExercisePickerSheet and shown as expandable cards
// where sets, reps, and weight are configured.
// BEGIN → creates the session and navigates to WorkoutSessionScreen.
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final LocalWorkoutTemplate? template;
  final WorkoutTemplate? routine;
  final bool saveAsRoutine;

  const WorkoutBuilderScreen({
    super.key,
    this.template,
    this.routine,
    this.saveAsRoutine = false,
  });

  @override
  ConsumerState<WorkoutBuilderScreen> createState() =>
      _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final List<BuilderExerciseEntry> _exercises = [];
  bool _isStarting = false;
  bool _loadingTemplate = false;
  bool _shareRoutine = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameCtrl.text = widget.template!.name;
      _loadTemplateExercises();
    } else if (widget.routine != null) {
      _nameCtrl.text = widget.routine!.name;
      _loadRoutineExercises();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Template loading ────────────────────────────────────────────────────────
  Future<void> _loadTemplateExercises() async {
    if (widget.template == null) return;
    setState(() => _loadingTemplate = true);
    // Use offline service — reads from local cache, no network needed
    final svc = ref.read(offlineWorkoutServiceProvider);

    for (final te in widget.template!.exercises) {
      try {
        final results = await svc.listExercises(query: te.exerciseName);
        final match = results.isNotEmpty ? results.first : null;
        if (match == null) continue;

        final sets = List.generate(
          te.sets,
          (_) => BuilderSet(reps: te.reps, durationSecs: te.durationSecs),
        );

        if (mounted) {
          setState(() {
            _exercises.add(BuilderExerciseEntry(
              uid: '${match.id}_${DateTime.now().microsecondsSinceEpoch}',
              exercise: match,
              sets: sets,
            ));
          });
        }
      } catch (e) {
        debugPrint('[WorkoutBuilder] template load exercise failed: $e');
      }
    }

    if (mounted) setState(() => _loadingTemplate = false);
  }

  Future<void> _loadRoutineExercises() async {
    final routine = widget.routine;
    if (routine == null) return;
    setState(() => _loadingTemplate = true);

    final offline = ref.read(offlineWorkoutServiceProvider);
    final loaded = await Future.wait(
      routine.exercises.map((planned) async {
        try {
          final exercise =
              planned.exercise ?? await offline.getExercise(planned.exerciseId);
          if (exercise == null) return null;
          final count = planned.defaultSets ?? 1;
          final sets = List.generate(
            count,
            (_) => BuilderSet(
              reps: planned.defaultReps,
              weightKg: planned.defaultWeightKg,
              durationSecs: planned.defaultDurationSecs,
              distanceM: planned.defaultDistanceM,
            ),
          );
          return BuilderExerciseEntry(
            uid: '${exercise.id}_${DateTime.now().microsecondsSinceEpoch}',
            exercise: exercise,
            sets: sets,
          );
        } catch (e) {
          debugPrint('[WorkoutBuilder] routine load exercise failed: $e');
          return null;
        }
      }),
    );
    if (mounted) {
      setState(() {
        _exercises.addAll(loaded.whereType<BuilderExerciseEntry>());
      });
    }
    if (mounted) setState(() => _loadingTemplate = false);
  }

  // ── Exercise management ────────────────────────────────────────────────────
  void _addExercise(Exercise ex) {
    setState(() {
      _exercises.add(BuilderExerciseEntry(
        uid: '${ex.id}_${DateTime.now().microsecondsSinceEpoch}',
        exercise: ex,
      ));
    });
  }

  void _removeExercise(String uid) {
    setState(() => _exercises.removeWhere((e) => e.uid == uid));
  }

  void _toggleExpand(String uid) {
    final idx = _exercises.indexWhere((e) => e.uid == uid);
    if (idx < 0) return;
    setState(() {
      _exercises[idx] = _exercises[idx]
          .copyWith(isExpanded: !_exercises[idx].isExpanded);
    });
  }

  void _addSet(String uid) {
    final idx = _exercises.indexWhere((e) => e.uid == uid);
    if (idx < 0) return;
    final entry = _exercises[idx];
    // Copy last set values as defaults for the new set
    final last = entry.sets.isNotEmpty ? entry.sets.last : BuilderSet();
    setState(() {
      _exercises[idx] = entry.copyWith(
        sets: [...entry.sets, BuilderSet(
          weightKg: last.weightKg,
          reps: last.reps,
          durationSecs: last.durationSecs,
          distanceM: last.distanceM,
        )],
      );
    });
  }

  void _removeSet(String uid, int setIndex) {
    final idx = _exercises.indexWhere((e) => e.uid == uid);
    if (idx < 0) return;
    final sets = List<BuilderSet>.from(_exercises[idx].sets);
    if (sets.length <= 1) return; // keep at least one set
    sets.removeAt(setIndex);
    setState(() {
      _exercises[idx] = _exercises[idx].copyWith(sets: sets);
    });
  }

  void _updateSet(String uid, int setIndex, BuilderSet updated) {
    final idx = _exercises.indexWhere((e) => e.uid == uid);
    if (idx < 0) return;
    final sets = List<BuilderSet>.from(_exercises[idx].sets);
    sets[setIndex] = updated;
    setState(() {
      _exercises[idx] = _exercises[idx].copyWith(sets: sets);
    });
  }

  // ── Start workout ──────────────────────────────────────────────────────────
  Future<void> _startWorkout() async {
    if (_exercises.isEmpty) return;
    setState(() => _isStarting = true);
    try {
      // Offline-first: writes to local DB immediately, syncs to server later.
      // This will NEVER fail due to a network issue.
      final svc = ref.read(offlineWorkoutServiceProvider);
      final name = _nameCtrl.text.trim();
      final session = await svc.createSession(
        notes: name.isEmpty ? null : name,
        templateId: widget.routine?.id,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSessionScreen(
            session: session,
            builderExercises: _exercises,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[WorkoutBuilder] startWorkout failed: $e');
      setState(() => _isStarting = false);
      if (mounted) {
        showAppSnack(
          context,
          "Couldn't start: ${e.toString().replaceAll('Exception: ', '')}",
          tone: AppSnackTone.error,
        );
      }
    }
  }

  Future<void> _saveRoutine() async {
    if (_exercises.isEmpty) return;
    setState(() => _isStarting = true);
    try {
      final exercises = _exercises.asMap().entries.map((entry) {
        final firstSet =
            entry.value.sets.isNotEmpty ? entry.value.sets.first : BuilderSet();
        return WorkoutTemplateExercise(
          id: '',
          templateId: '',
          exerciseId: entry.value.exercise.id,
          sortOrder: entry.key,
          defaultSets: entry.value.sets.length,
          defaultReps: firstSet.reps,
          defaultWeightKg: firstSet.weightKg,
          defaultDurationSecs: firstSet.durationSecs,
          defaultDistanceM: firstSet.distanceM,
        );
      }).toList();
      await ref.read(workoutServiceProvider).createRoutine(
            name: _nameCtrl.text.trim().isEmpty
                ? 'My Routine'
                : _nameCtrl.text.trim(),
            exercises: exercises,
            isShared: _shareRoutine,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save routine: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _exercises.isNotEmpty && !_isStarting;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Symbols.close, size: 18),
                  ),
                ),
                title: TextField(
                  controller: _nameCtrl,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Workout name...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                actions: [
                  // BEGIN button — disabled until exercises added
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: canStart
                          ? (widget.saveAsRoutine ? _saveRoutine : _startWorkout)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: canStart
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          boxShadow: canStart
                              ? AppTheme.neonGlow(opacity: 0.3)
                              : null,
                        ),
                        child: _isStarting
                            ? SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.onPrimaryFixed,
                                  ),
                                ),
                              )
                            : Text(
                                widget.saveAsRoutine ? 'Save' : 'Begin',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                  color: canStart
                                      ? AppTheme.onPrimaryFixed
                                      : AppTheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Offline banner ────────────────────────────────────
              if (!isOnline)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin, 8,
                        AppTheme.containerMargin, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 14,
                            color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Offline mode — workout will sync when connected',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Loading template spinner ──────────────────────────────
              if (_loadingTemplate)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            AppTheme.primaryContainer),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              if (widget.saveAsRoutine)
                SliverToBoxAdapter(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.containerMargin,
                    ),
                    title: const Text('Share with my gym'),
                    subtitle: const Text(
                      'Other members can discover and copy this routine',
                    ),
                    value: _shareRoutine,
                    activeColor: AppTheme.primaryContainer,
                    onChanged: (value) => setState(() => _shareRoutine = value),
                  ),
                ),

              // ── Exercise list ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.containerMargin),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BuilderExerciseCard(
                        entry: _exercises[i],
                        exerciseNumber: i + 1,
                        onOpenInfo: () => ExerciseInfoSheet.show(
                          context,
                          exercise: _exercises[i].exercise,
                          routineId: widget.routine?.id,
                        ),
                        onToggleExpand: () => _toggleExpand(_exercises[i].uid),
                        onRemove: () => _removeExercise(_exercises[i].uid),
                        onAddSet: () => _addSet(_exercises[i].uid),
                        onRemoveSet: (si) =>
                            _removeSet(_exercises[i].uid, si),
                        onUpdateSet: (si, s) =>
                            _updateSet(_exercises[i].uid, si, s),
                      ),
                    ),
                    childCount: _exercises.length,
                  ),
                ),
              ),

              // ── Empty state ───────────────────────────────────────────
              if (_exercises.isEmpty && !_loadingTemplate)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin, 60,
                        AppTheme.containerMargin, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Icon(Symbols.fitness_center, size: 32,
                            color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        Text('No exercises yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                              )),
                        const SizedBox(height: 6),
                        Text('Tap Add exercise to build your workout',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                  child: SizedBox(height: bottomPad + 120)),
            ],
          ),

          // ── ADD EXERCISE button (sticky bottom) ──────────────────────
          Positioned(
            left: AppTheme.containerMargin,
            right: AppTheme.containerMargin,
            bottom: bottomPad + 16,
            child: SecondaryButton(
              label: 'Add exercise',
              icon: Symbols.add,
              onPressed: () => ExercisePickerSheet.show(
                context,
                onExerciseSelected: _addExercise,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BuilderExerciseCard — expandable card for one exercise in the builder
// ─────────────────────────────────────────────────────────────────────────────
class _BuilderExerciseCard extends StatelessWidget {
  final BuilderExerciseEntry entry;
  final int exerciseNumber;
  final VoidCallback onOpenInfo;
  final VoidCallback onToggleExpand;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int index, BuilderSet updated) onUpdateSet;

  const _BuilderExerciseCard({
    required this.entry,
    required this.exerciseNumber,
    required this.onOpenInfo,
    required this.onToggleExpand,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
  });

  @override
  Widget build(BuildContext context) {
    final ex = entry.exercise;
    final isCardio = ex.isCardio;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                ExerciseThumbnail(exercise: ex, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenInfo,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryContainer,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (ex.category != null) ex.category!,
                            '${entry.sets.length} set${entry.sets.length > 1 ? 's' : ''}',
                          ].join(' · '),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Symbols.delete,
                      size: 14,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleExpand,
                  icon: Icon(
                    entry.isExpanded
                        ? Symbols.keyboard_arrow_up
                        : Symbols.keyboard_arrow_down,
                    size: 20,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── Set rows (visible when expanded) ────────────────────────
          if (entry.isExpanded) ...[
            Divider(height: 1, color: Colors.white.withOpacity(0.06)),
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: _SetTableHeader(isCardio: isCardio),
            ),
            ...entry.sets.asMap().entries.map((e) =>
              _BuilderSetRow(
                setIndex: e.key,
                set: e.value,
                isCardio: isCardio,
                isWeighted: ex.isWeighted,
                isAssisted: ex.isAssisted,
                isBodyweight: ex.isBodyweight,
                onUpdate: (s) => onUpdateSet(e.key, s),
                onRemove: () => onRemoveSet(e.key),
                canRemove: entry.sets.length > 1,
              ),
            ),
            // Add set button
            GestureDetector(
              onTap: onAddSet,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(color: Colors.white.withOpacity(0.1),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.add, size: 14,
                        color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Add Set',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  final bool isCardio;
  const _SetTableHeader({required this.isCardio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Hdr('SET', flex: 1),
        if (isCardio) ...[
          _Hdr('MIN', flex: 2),
          _Hdr('KM', flex: 2),
          _Hdr('KM/H', flex: 2),
        ] else ...[
          _Hdr('KG', flex: 2),
          _Hdr('REPS', flex: 2),
          _Hdr('RPE', flex: 2),
        ],
        const SizedBox(width: 28),
      ],
    );
  }
}

class _Hdr extends StatelessWidget {
  final String label;
  final int flex;
  const _Hdr(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppTheme.onSurfaceVariant)),
    );
  }
}

class _BuilderSetRow extends StatefulWidget {
  final int setIndex;
  final BuilderSet set;
  final bool isCardio;
  final bool isWeighted;
  final bool isAssisted;
  final bool isBodyweight;
  final ValueChanged<BuilderSet> onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const _BuilderSetRow({
    required this.setIndex,
    required this.set,
    required this.isCardio,
    required this.isWeighted,
    required this.isAssisted,
    required this.isBodyweight,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<_BuilderSetRow> createState() => _BuilderSetRowState();
}

class _BuilderSetRowState extends State<_BuilderSetRow> {
  late final TextEditingController _c1; // kg / mins
  late final TextEditingController _c2; // reps / km
  late final TextEditingController _c3; // rpe / km/h

  @override
  void initState() {
    super.initState();
    if (widget.isCardio) {
      final mins = widget.set.durationSecs != null
          ? (widget.set.durationSecs! / 60).toStringAsFixed(0)
          : '';
      final km = widget.set.distanceM != null
          ? (widget.set.distanceM! / 1000).toStringAsFixed(2)
          : '';
      _c1 = TextEditingController(text: mins);
      _c2 = TextEditingController(text: km);
      _c3 = TextEditingController(
          text: widget.set.speedKph?.toString() ?? '');
    } else {
      _c1 = TextEditingController(
          text: widget.set.weightKg?.toString() ?? '');
      _c2 = TextEditingController(text: widget.set.reps?.toString() ?? '');
      _c3 = TextEditingController(text: widget.set.rpe?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  void _emit() {
    if (widget.isCardio) {
      final mins = double.tryParse(_c1.text);
      final km = double.tryParse(_c2.text);
      widget.onUpdate(widget.set.copyWith(
        durationSecs: mins != null ? (mins * 60).round() : null,
        distanceM: km != null ? km * 1000 : null,
        speedKph: double.tryParse(_c3.text),
      ));
    } else {
      widget.onUpdate(widget.set.copyWith(
        weightKg: widget.isBodyweight ? null : double.tryParse(_c1.text),
        reps: int.tryParse(_c2.text),
        rpe: double.tryParse(_c3.text),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${widget.setIndex + 1}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          // Col 1 — kg (hidden for bodyweight) or mins
          Expanded(
            flex: 2,
            child: widget.isBodyweight
                ? Text('BW',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant))
                : _InlineInput(
                    controller: _c1,
                    hint: widget.isCardio ? '30' : '0',
                    onChanged: (_) => _emit(),
                  ),
          ),
          // Col 2 — reps or km
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: _c2,
              hint: widget.isCardio ? '5.0' : '0',
              onChanged: (_) => _emit(),
            ),
          ),
          // Col 3 — rpe or km/h
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: _c3,
              hint: widget.isCardio ? '0' : '—',
              onChanged: (_) => _emit(),
            ),
          ),
          // Remove set
          GestureDetector(
            onTap: widget.canRemove ? widget.onRemove : null,
            child: SizedBox(
              width: 28,
              child: Icon(Symbols.close, size: 14,
                color: widget.canRemove
                    ? AppTheme.onSurfaceVariant.withOpacity(0.5)
                    : Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _InlineInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppTheme.onSurfaceVariant.withOpacity(0.4)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: AppTheme.primaryContainer.withOpacity(0.5), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        isDense: true,
      ),
    );
  }
}
