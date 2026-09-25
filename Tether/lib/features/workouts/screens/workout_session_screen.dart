import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/sync/connectivity_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import '../../social/providers/feed_provider.dart';
import '../../social/services/pending_workout_share_queue.dart';
import '../../social/services/post_media_service.dart';
import '../../social/services/social_service.dart';
import '../../home/providers/home_data_provider.dart';
import 'exercise_picker_sheet.dart';
import '../widgets/exercise_info_sheet.dart';
import '../widgets/hevy_exercise_card.dart';
import '../widgets/workout_stats_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSessionScreen
//
// Two modes:
//   session == null  → "Name your workout" dialog, then creates a new session
//   session != null  → Active logging view with elapsed timer, set tables,
//                      rest timer, and PR badges
//
// builderExercises: optional list from WorkoutBuilderScreen — pre-populates
// the set tables with the exercises the user planned (but sets are empty
// until actually logged).
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final WorkoutSession? session;
  final List<BuilderExerciseEntry>? builderExercises;

  const WorkoutSessionScreen({super.key, this.session, this.builderExercises});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  // ── Session state ──────────────────────────────────────────────────────────
  WorkoutSession? _session;
  bool _isCreating = false;
  bool _isEnding = false;
  String? _error;

  // ── Sets (local mirror — avoids re-fetching after each add) ───────────────
  // Map: exerciseId → list of sets in insertion order
  final Map<String, List<_LocalSet>> _setsByExercise = {};
  // Ordered exercise IDs so the UI renders in the order exercises were added
  final List<String> _exerciseOrder = [];
  // Exercise lookup map so we can display names without a full re-fetch
  final Map<String, Exercise> _exerciseMap = {};
  final Map<String, List<DraftSetEntry>> _draftSetsByExercise = {};
  final Map<String, ProgressData?> _previousByExercise = {};
  final Map<String, bool> _restEnabledByExercise = {};
  final Map<String, String> _notesByExercise = {};
  int _prCount = 0;
  String? _lastPrExerciseName;
  String? _lastPrValue;
  String? _lastPrImageUrl;

  // ── Elapsed timer ──────────────────────────────────────────────────────────
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // ── Rest timer ─────────────────────────────────────────────────────────────
  int _restDurationSecs = 90; // per-session setting, adjustable
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _restActive = false;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _prBannerCtrl;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _prBannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (_session != null) {
      _startElapsedTimer();
      _buildLocalSetsFromSession(_session!);
      // Pre-populate from builder exercises (they start with empty set rows)
      if (widget.builderExercises != null) {
        for (final entry in widget.builderExercises!) {
          final id = entry.exercise.id;
          if (!_setsByExercise.containsKey(id)) {
            _setsByExercise[id] = [];
            _exerciseOrder.add(id);
            _exerciseMap[id] = entry.exercise;
          }
          _draftSetsByExercise[id] = entry.sets.isEmpty
              ? [DraftSetEntry.empty()]
              : entry.sets
                  .asMap()
                  .entries
                  .map(
                    (e) => DraftSetEntry(
                      localId: '${id}_${e.key}',
                      weightKg: e.value.weightKg ?? 0,
                      reps: e.value.reps ?? 0,
                      rpe: e.value.rpe,
                    ),
                  )
                  .toList();
          _loadPreviousForExercise(id);
        }
      }
      _ensureDraftRowsForExercises();
    } else {
      // Show the "name your workout" dialog after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNameDialog());
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _prBannerCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _buildLocalSetsFromSession(WorkoutSession session) {
    for (final set in session.sets) {
      if (!_setsByExercise.containsKey(set.exerciseId)) {
        _setsByExercise[set.exerciseId] = [];
        _exerciseOrder.add(set.exerciseId);
        if (set.exercise != null) {
          _exerciseMap[set.exerciseId] = set.exercise!;
        }
      }
      _setsByExercise[set.exerciseId]!.add(_LocalSet.fromWorkoutSet(set));
    }
    _ensureDraftRowsForExercises();
  }

  void _ensureDraftRowsForExercises() {
    if (_session?.endedAt != null) return;
    for (final exerciseId in _exerciseOrder) {
      final drafts = _draftSetsByExercise[exerciseId];
      if (drafts == null || drafts.isEmpty) {
        _draftSetsByExercise[exerciseId] = [DraftSetEntry.empty()];
      }
      if (!_previousByExercise.containsKey(exerciseId)) {
        _loadPreviousForExercise(exerciseId);
      }
    }
  }

  /// Persists draft rows that already have weight + reps so Finish cannot
  /// create hollow sessions when the user skipped the checkmark.
  Future<void> _flushFilledDrafts() async {
    final pending = <({String exerciseId, DraftSetEntry draft})>[];
    for (final exerciseId in List<String>.from(_exerciseOrder)) {
      final drafts =
          List<DraftSetEntry>.from(_draftSetsByExercise[exerciseId] ?? const []);
      for (final draft in drafts) {
        if (draft.weightKg > 0 && draft.reps > 0) {
          pending.add((exerciseId: exerciseId, draft: draft));
        }
      }
    }
    for (final item in pending) {
      await _completeDraftSet(
        item.exerciseId,
        item.draft,
        item.draft.weightKg,
        item.draft.reps,
        item.draft.rpe,
      );
    }
  }

  double get _totalVolumeKg => _setsByExercise.values
      .expand((sets) => sets)
      .fold<double>(0, (sum, set) => sum + set.weightKg * set.reps);

  int get _totalSets =>
      _setsByExercise.values.fold(0, (sum, sets) => sum + sets.length);

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    if (_session == null) return;
    final start = _session!.startedAt;
    final endedAt = _session!.endedAt;
    if (endedAt != null) {
      _elapsed = endedAt.difference(start);
      return;
    }
    _elapsed = DateTime.now().difference(start);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ─── Name dialog ────────────────────────────────────────────────────────────

  Future<void> _showNameDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showAppDialog<String>(
      context,
      barrierDismissible: false,
      builder: (_) => _WorkoutNameDialog(controller: nameCtrl),
    );
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
      return;
    }
    await _createSession(result.isEmpty ? null : result);
  }

  // ─── Session CRUD ────────────────────────────────────────────────────────────

  Future<void> _createSession(String? name) async {
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final session = await svc.createSession(notes: name);
      setState(() {
        _session = session;
        _isCreating = false;
      });
      _startElapsedTimer();
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] createSession failed: $e');
      setState(() {
        _isCreating = false;
        _error = "Couldn't start workout";
      });
    }
  }

  Future<void> _endSession() async {
    if (_session == null) return;
    final confirmed = await _showEndConfirm();
    if (!confirmed || !mounted) return;

    // Stop live timers while we flush drafts + persist. Keep the session
    // editable (not read-only) until drafts are saved so cards don't go hollow.
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _isEnding = true;
      _error = null;
      _restActive = false;
    });

    try {
      await _flushFilledDrafts();
      if (!mounted) return;

      final finishedAt = DateTime.now();
      setState(() {
        _elapsed = finishedAt.difference(_session!.startedAt);
        _session = WorkoutSession(
          id: _session!.id,
          userId: _session!.userId,
          gymId: _session!.gymId,
          templateId: _session!.templateId,
          startedAt: _session!.startedAt,
          endedAt: finishedAt,
          notes: _session!.notes,
          sets: _session!.sets,
        );
      });
      // Drop Home "in progress" card before navigation.
      ref.invalidate(homeDataProvider);

      final svc = ref.read(offlineWorkoutServiceProvider);
      final endedSession = await svc.endSession(
        _session!.id,
        notes: _session!.notes,
      );
      if (endedSession.endedAt != null) {
        _elapsed = endedSession.endedAt!.difference(endedSession.startedAt);
      }
      ref.invalidate(homeDataProvider);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutCompleteScreen(
              sessionId: endedSession.id,
              duration: _elapsed,
              totalSets: _setsByExercise.values.fold(
                0,
                (sum, sets) => sum + sets.length,
              ),
              exerciseCount: _exerciseOrder.length,
              prCount: _prCount,
              totalVolume: _setsByExercise.values
                  .expand((sets) => sets)
                  .fold<double>(0, (sum, set) => sum + set.weightKg * set.reps),
              workoutName: _session!.notes,
              initialCaption: _exerciseNotesSummary(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] endSession failed: $e');
      if (!mounted) return;
      setState(() {
        _isEnding = false;
        _error = "Couldn't save workout";
        _session = WorkoutSession(
          id: _session!.id,
          userId: _session!.userId,
          gymId: _session!.gymId,
          templateId: _session!.templateId,
          startedAt: _session!.startedAt,
          endedAt: null,
          notes: _session!.notes,
          sets: _session!.sets,
        );
      });
      ref.invalidate(homeDataProvider);
      _startElapsedTimer();
    }
  }

  String? _exerciseNotesSummary() {
    final lines = <String>[];
    for (final id in _exerciseOrder) {
      final note = _notesByExercise[id]?.trim() ?? '';
      if (note.isEmpty) continue;
      lines.add('${_exerciseMap[id]?.name ?? 'Exercise'}: $note');
    }
    return lines.isEmpty ? null : lines.join('\n');
  }

  Future<bool> _showEndConfirm() async {
    final logged = _setsByExercise.values.fold(0, (sum, sets) => sum + sets.length);
    final unloggedFilled = _draftSetsByExercise.values
        .expand((drafts) => drafts)
        .where((d) => d.weightKg > 0 && d.reps > 0)
        .length;
    return await showAppDialog<bool>(
          context,
          builder: (_) => _EndWorkoutDialog(
            duration: _formatElapsed(_elapsed),
            setCount: logged,
            pendingFilledCount: unloggedFilled,
          ),
        ) ??
        false;
  }

  // ─── Exercise management ─────────────────────────────────────────────────────

  Future<void> _loadPreviousForExercise(String exerciseId) async {
    try {
      final history =
          await ref.read(workoutServiceProvider).getProgress(exerciseId);
      if (mounted) {
        setState(() {
          _previousByExercise[exerciseId] =
              history.isNotEmpty ? history.last : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _previousByExercise[exerciseId] = null);
    }
  }

  Future<void> _openExerciseInfo(String exerciseId) async {
    final exercise = _exerciseMap[exerciseId];
    if (exercise == null) return;
    await ExerciseInfoSheet.show(
      context,
      exercise: exercise,
      routineId: _session?.templateId,
    );
  }

  Future<void> _pickExercise() async {
    await ExercisePickerSheet.show(
      context,
      onExerciseSelected: _addExercise,
    );
  }

  void _addExercise(Exercise ex) {
    setState(() {
      if (!_exerciseOrder.contains(ex.id)) {
        _exerciseOrder.add(ex.id);
        _exerciseMap[ex.id] = ex;
        _setsByExercise[ex.id] = [];
        _draftSetsByExercise[ex.id] = [DraftSetEntry.empty()];
        _loadPreviousForExercise(ex.id);
      }
    });
  }

  void _addDraftSet(String exerciseId) {
    setState(() {
      final drafts = _draftSetsByExercise.putIfAbsent(
        exerciseId,
        () => <DraftSetEntry>[],
      );
      drafts.add(DraftSetEntry.empty());
    });
  }

  Future<void> _removeExercise(String exerciseId) async {
    final logged = List<_LocalSet>.from(_setsByExercise[exerciseId] ?? const []);
    if (logged.isNotEmpty) {
      final count = logged.length;
      final confirmed = await showAppConfirmDialog(
        context,
        icon: Symbols.delete,
        tone: AppDialogTone.danger,
        title: 'Remove ${_exerciseMap[exerciseId]?.name ?? 'exercise'}?',
        message:
            'This also deletes the $count set${count == 1 ? '' : 's'} you logged for it.',
        confirmLabel: 'Remove',
      );
      if (confirmed != true || !mounted) return;
    }

    final svc = ref.read(offlineWorkoutServiceProvider);
    final deleted = <_LocalSet>[];
    for (final set in logged) {
      try {
        await svc.deleteSet(set.id);
        deleted.add(set);
      } catch (e) {
        debugPrint('[WorkoutSessionScreen] removeExercise failed: $e');
        if (!mounted) return;
        setState(() {
          _setsByExercise[exerciseId]?.removeWhere(deleted.contains);
          _prCount -= deleted.where((s) => s.isPr).length;
        });
        showAppSnack(
          context,
          "Couldn't remove all sets. Check your connection and try again.",
          tone: AppSnackTone.error,
        );
        return;
      }
    }
    if (!mounted) return;

    setState(() {
      _prCount -= deleted.where((s) => s.isPr).length;
      _exerciseOrder.remove(exerciseId);
      _draftSetsByExercise.remove(exerciseId);
      _restEnabledByExercise.remove(exerciseId);
      _notesByExercise.remove(exerciseId);
      _setsByExercise.remove(exerciseId);
      _exerciseMap.remove(exerciseId);
    });
  }

  // ─── Log set ─────────────────────────────────────────────────────────────────

  Future<void> _completeDraftSet(
    String exerciseId,
    DraftSetEntry draft,
    double weight,
    int reps,
    double? rpe,
  ) async {
    if (_session == null) return;

    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final ex = _exerciseMap[exerciseId];
      if (ex == null) return;
      final setNum = (_setsByExercise[exerciseId] ?? const <_LocalSet>[])
              .fold<int>(0, (max, s) => s.setNumber > max ? s.setNumber : max) +
          1;

      final result = await svc.addSet(
        _session!.id,
        exerciseId: exerciseId,
        setNumber: setNum,
        reps: reps,
        weightKg: weight,
        rpe: rpe,
      );

      if (!_setsByExercise.containsKey(exerciseId)) {
        _setsByExercise[exerciseId] = [];
        if (!_exerciseOrder.contains(exerciseId)) {
          _exerciseOrder.add(exerciseId);
        }
        _exerciseMap[exerciseId] = ex;
      }
      _setsByExercise[exerciseId]!.add(
        _LocalSet(
          id: result.set.id,
          exercise: ex,
          setNumber: setNum,
          weightKg: weight,
          reps: reps,
          rpe: rpe,
          isPr: result.isPr,
        ),
      );

      if (result.isPr) {
        _prCount++;
        _lastPrExerciseName = ex.name;
        _lastPrValue = '${weight}kg × $reps reps';
        final bodyPart = ex.bodyParts.isNotEmpty ? ex.bodyParts.first : null;
        _lastPrImageUrl = _prImageForBodyPart(bodyPart);
        _prBannerCtrl.forward(from: 0);
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      if (!mounted) return;
      setState(() {
        final drafts = _draftSetsByExercise[exerciseId];
        drafts?.remove(draft);
        if (drafts != null && drafts.isEmpty) drafts.add(DraftSetEntry.empty());
      });

      if (_restEnabledByExercise[exerciseId] == true) {
        _startRestTimer();
      }
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] completeDraftSet failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save set")),
        );
      }
    }
  }

  /// Un-ticks a logged set: it goes back to an editable row with the same
  /// values. The exercise always stays in the workout.
  Future<void> _uncompleteSet(String exerciseId, String setId) async {
    final sets = _setsByExercise[exerciseId];
    final index = sets?.indexWhere((s) => s.id == setId) ?? -1;
    if (sets == null || index < 0) return;
    final removed = sets[index];
    final restored = DraftSetEntry(
      localId: 'undo_${removed.id}',
      weightKg: removed.weightKg,
      reps: removed.reps,
      rpe: removed.rpe,
    );

    setState(() {
      sets.removeAt(index);
      if (removed.isPr && _prCount > 0) _prCount--;
      _draftSetsByExercise.putIfAbsent(exerciseId, () => []).insert(0, restored);
    });

    try {
      await ref.read(offlineWorkoutServiceProvider).deleteSet(removed.id);
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] uncompleteSet failed: $e');
      if (!mounted) return;
      setState(() {
        final current = _setsByExercise.putIfAbsent(exerciseId, () => []);
        current.insert(index.clamp(0, current.length), removed);
        if (removed.isPr) _prCount++;
        _draftSetsByExercise[exerciseId]?.remove(restored);
      });
      showAppSnack(
        context,
        "Couldn't undo that set. Check your connection and try again.",
        tone: AppSnackTone.error,
      );
    }
  }

  // ─── Rest timer ──────────────────────────────────────────────────────────────

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restActive = true;
      _restRemaining = _restDurationSecs;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) {
          _restActive = false;
          t.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _dismissRest() {
    _restTimer?.cancel();
    setState(() => _restActive = false);
  }

  void _toggleRestForExercise(String exerciseId) {
    setState(() {
      _restEnabledByExercise[exerciseId] =
          !(_restEnabledByExercise[exerciseId] ?? false);
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
          ),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: _error != null
              ? ConnectErrorState(onRetry: () => _showNameDialog())
              : const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
                ),
        ),
      );
    }

    final isCompleted = _session!.endedAt != null;

    return PopScope(
      canPop: !_isEnding,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            // ── Main scrollable content ──────────────────────────────────────
            CustomScrollView(
              slivers: [
                // Sticky header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SessionHeaderDelegate(
                    session: _session!,
                    elapsed: _formatElapsed(_elapsed),
                    isEnding: _isEnding,
                    onEnd: _endSession,
                    topInset: MediaQuery.of(context).padding.top,
                    isCompleted: isCompleted,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: WorkoutStatsBar(
                      elapsed: _elapsed,
                      totalVolumeKg: _totalVolumeKg,
                      totalSets: _totalSets,
                      exercises: _exerciseOrder
                          .map((id) => _exerciseMap[id])
                          .whereType<Exercise>(),
                    ),
                  ),
                ),

                // Error banner
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin,
                        12,
                        AppTheme.containerMargin,
                        0,
                      ),
                      child: _InlineBanner(message: _error!, isError: true),
                    ),
                  ),

                // PR banner
                SliverToBoxAdapter(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _prBannerCtrl,
                      curve: Curves.elasticOut,
                    ),
                    child: _prBannerCtrl.value > 0
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.containerMargin,
                              12,
                              AppTheme.containerMargin,
                              0,
                            ),
                            child: _PrBanner(
                              prCount: _prCount,
                              lastPrExerciseName: _lastPrExerciseName,
                              lastPrValue: _lastPrValue,
                              lastPrImageUrl: _lastPrImageUrl,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Exercise cards (Hevy-style inline logging)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.containerMargin,
                    0,
                    AppTheme.containerMargin,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final exerciseId = _exerciseOrder[i];
                      final exercise = _exerciseMap[exerciseId];
                      if (exercise == null) return const SizedBox.shrink();
                      final logged = (_setsByExercise[exerciseId] ?? [])
                          .map(
                            (s) => LoggedSetEntry(
                              id: s.id,
                              setNumber: s.setNumber,
                              weightKg: s.weightKg,
                              reps: s.reps,
                              rpe: s.rpe,
                              isPr: s.isPr,
                            ),
                          )
                          .toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HevyExerciseCard(
                          key: ValueKey(exerciseId),
                          exercise: exercise,
                          loggedSets: logged,
                          draftSets: isCompleted
                              ? const []
                              : (_draftSetsByExercise[exerciseId]
                                          ?.isNotEmpty ==
                                      true
                                  ? _draftSetsByExercise[exerciseId]!
                                  : [DraftSetEntry.empty()]),
                          previousSet: _previousByExercise[exerciseId],
                          readOnly: isCompleted,
                          restEnabled: _restEnabledByExercise[exerciseId] ?? false,
                          onOpenInfo: () => _openExerciseInfo(exerciseId),
                          onAddDraftSet: () => _addDraftSet(exerciseId),
                          onRemoveExercise: isCompleted
                              ? null
                              : () => _removeExercise(exerciseId),
                          onToggleRest: isCompleted
                              ? null
                              : () => _toggleRestForExercise(exerciseId),
                          onCompleteDraft: (draft, weight, reps, rpe) =>
                              _completeDraftSet(
                            exerciseId,
                            draft,
                            weight,
                            reps,
                            rpe,
                          ),
                          onUncompleteSet: (set) =>
                              _uncompleteSet(exerciseId, set.id),
                          notes: _notesByExercise[exerciseId] ?? '',
                          onNotesChanged: (value) =>
                              _notesByExercise[exerciseId] = value,
                        ),
                      );
                    }, childCount: _exerciseOrder.length),
                  ),
                ),

                // Empty state
                if (_exerciseOrder.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin,
                        AppTheme.stackLg,
                        AppTheme.containerMargin,
                        0,
                      ),
                      child: _EmptySessionState(),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: isCompleted
                        ? 32
                        : MediaQuery.of(context).padding.bottom + 96,
                  ),
                ),
              ],
            ),

            // ── Rest timer overlay ───────────────────────────────────────────
            if (_restActive)
              Positioned(
                left: AppTheme.containerMargin,
                right: AppTheme.containerMargin,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: _RestTimerCard(
                  remaining: _restRemaining,
                  total: _restDurationSecs,
                  onDismiss: _dismissRest,
                  onAdjust: (secs) => setState(() => _restDurationSecs = secs),
                ),
              ),
            if (!_restActive && !isCompleted)
              Positioned(
                left: AppTheme.containerMargin,
                right: AppTheme.containerMargin,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: PrimaryButton(
                  label: 'Add exercise',
                  icon: Symbols.add,
                  onPressed: _pickExercise,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _prImageForBodyPart(String? bodyPart) {
  const map = {
    'chest':
        'https://images.unsplash.com/photo-1534368786749-b63e05c92717?w=800&q=80',
    'back':
        'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=80',
    'upper arms':
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
    'shoulders':
        'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=80',
    'upper legs':
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
    'lower legs':
        'https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=800&q=80',
    'waist':
        'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80',
    'cardio':
        'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=80',
  };
  return map[bodyPart?.toLowerCase()] ??
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80';
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocalSet — in-memory mirror of a WorkoutSet with isPr flag
// ─────────────────────────────────────────────────────────────────────────────
class _LocalSet {
  final String id;
  final Exercise exercise;
  final int setNumber;
  final double weightKg;
  final int reps;
  final double? rpe;
  final bool isPr;

  const _LocalSet({
    required this.id,
    required this.exercise,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.isPr = false,
  });

  factory _LocalSet.fromWorkoutSet(WorkoutSet s) => _LocalSet(
    id: s.id,
    exercise:
        s.exercise ??
        Exercise(id: s.exerciseId, name: 'Exercise', isCustom: false),
    setNumber: s.setNumber ?? 1,
    weightKg: s.weightKg ?? 0,
    reps: s.reps ?? 0,
    rpe: s.rpe,
    isPr: false,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky session header — elapsed timer + workout name + End button
// ─────────────────────────────────────────────────────────────────────────────
class _SessionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WorkoutSession session;
  final String elapsed;
  final bool isEnding;
  final VoidCallback onEnd;
  final double topInset;
  final bool isCompleted;

  const _SessionHeaderDelegate({
    required this.session,
    required this.elapsed,
    required this.isEnding,
    required this.onEnd,
    required this.topInset,
    required this.isCompleted,
  });

  @override
  double get minExtent => topInset + 56;
  @override
  double get maxExtent => topInset + 56;

  @override
  bool shouldRebuild(_SessionHeaderDelegate old) =>
      elapsed != old.elapsed ||
      isEnding != old.isEnding ||
      topInset != old.topInset ||
      isCompleted != old.isCompleted;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        left: AppTheme.containerMargin,
        right: AppTheme.containerMargin,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                onPressed: isEnding ? null : () => Navigator.pop(context),
                icon: const Icon(
                  Symbols.keyboard_arrow_down,
                  size: 28,
                  color: AppTheme.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isCompleted
                      ? ((session.notes?.isNotEmpty == true)
                          ? session.notes!
                          : 'Workout session')
                      : 'Log workout',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isCompleted) ...[
                Text(
                  elapsed,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Symbols.timer,
                  size: 18,
                  color: AppTheme.primaryContainer,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: isEnding ? null : onEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.neonGlow(opacity: 0.22, blur: 14),
                    ),
                    child: isEnding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppTheme.onPrimaryFixed,
                              ),
                            ),
                          )
                        : Text(
                            'Finish',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.onPrimaryFixed,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RestTimerCard — bottom overlay that auto-starts after each set
// ─────────────────────────────────────────────────────────────────────────────
class _RestTimerCard extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onDismiss;
  final ValueChanged<int> onAdjust;

  const _RestTimerCard({
    required this.remaining,
    required this.total,
    required this.onDismiss,
    required this.onAdjust,
  });

  String get _display {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? remaining / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
          ...AppTheme.neonGlow(opacity: 0.15),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.timer,
                size: 16,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Rest',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // ─10s
              _AdjustButton(
                label: '−10',
                onTap: () => onAdjust((total - 10).clamp(10, 300)),
              ),
              const SizedBox(width: 8),
              // +10s
              _AdjustButton(
                label: '+10',
                onTap: () => onAdjust((total + 10).clamp(10, 300)),
              ),
              const SizedBox(width: 8),
              // Dismiss
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Symbols.close,
                    size: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining <= 10 ? AppTheme.error : AppTheme.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Countdown
          Text(
            _display,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: remaining <= 10
                  ? AppTheme.error
                  : AppTheme.primaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs
// ─────────────────────────────────────────────────────────────────────────────

class _WorkoutNameDialog extends StatelessWidget {
  final TextEditingController controller;
  const _WorkoutNameDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Symbols.fitness_center,
      tone: AppDialogTone.accent,
      title: 'Name your workout',
      message: 'Give it a name, or leave it blank to start straight away.',
      body: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.go,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: 'e.g. Push day, Leg day…',
          hintStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant),
          filled: true,
          fillColor: AppTheme.surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.hairlineStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppTheme.primaryContainer.withOpacity(0.7),
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        AppDialogButton(
          label: 'Cancel',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogButton(
          label: 'Start',
          icon: Symbols.play_arrow,
          onPressed: () => Navigator.pop(context, controller.text),
        ),
      ],
    );
  }
}

class _EndWorkoutDialog extends StatelessWidget {
  final String duration;
  final int setCount;
  final int pendingFilledCount;
  const _EndWorkoutDialog({
    required this.duration,
    required this.setCount,
    this.pendingFilledCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final totalSets = setCount + pendingFilledCount;
    return AppDialog(
      icon: Symbols.flag,
      tone: AppDialogTone.accent,
      title: 'Finish workout?',
      message: pendingFilledCount > 0
          ? '$pendingFilledCount filled set${pendingFilledCount == 1 ? '' : 's'} not yet ticked off will be saved too.'
          : totalSets == 0
              ? 'No sets logged yet. You can keep going or finish anyway.'
              : null,
      body: Row(
        children: [
          Expanded(child: _DialogStat(label: 'Duration', value: duration)),
          const SizedBox(width: 10),
          Expanded(child: _DialogStat(label: 'Sets', value: '$totalSets')),
        ],
      ),
      actions: [
        AppDialogButton(
          label: 'Keep going',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogButton(
          label: 'Finish',
          icon: Symbols.check,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

class _DialogStat extends StatelessWidget {
  final String label;
  final String value;
  const _DialogStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small utility widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InlineBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _InlineBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppTheme.errorContainer.withOpacity(0.15)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isError
              ? AppTheme.error.withOpacity(0.3)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Symbols.error : Symbols.info,
            size: 14,
            color: isError ? AppTheme.error : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError ? AppTheme.error : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrBanner extends StatelessWidget {
  final int prCount;
  final String? lastPrExerciseName;
  final String? lastPrValue;
  final String? lastPrImageUrl;

  const _PrBanner({
    required this.prCount,
    this.lastPrExerciseName,
    this.lastPrValue,
    this.lastPrImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.4)),
        boxShadow: AppTheme.neonGlow(opacity: 0.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: AppTheme.neonGlow(opacity: 0.5, blur: 10),
            ),
            child: Text(
              'PR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onPrimaryFixed,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prCount == 1
                  ? 'New personal record!'
                  : '$prCount personal records this session!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySessionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(
            Symbols.fitness_center,
            size: 28,
            color: AppTheme.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No sets yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add an exercise below and log your first set',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutCompleteScreen — post-workout summary
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Duration duration;
  final int totalSets;
  final int exerciseCount;
  final int prCount;
  final double totalVolume;
  final String? workoutName;
  final String? initialCaption;

  const WorkoutCompleteScreen({
    super.key,
    required this.sessionId,
    required this.duration,
    required this.totalSets,
    required this.exerciseCount,
    required this.prCount,
    required this.totalVolume,
    this.workoutName,
    this.initialCaption,
  });

  @override
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  bool _isSharing = false;
  bool _isShared = false;
  bool _isQueued = false;
  bool _isUploadingPhoto = false;
  String? _imagePath;
  XFile? _selectedPhoto;
  late final TextEditingController _captionCtrl;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.initialCaption ?? '');
    _titleCtrl = TextEditingController(text: widget.workoutName ?? '');
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _pickPhoto() async {
    final source = await showAppActionSheet<ImageSource>(
      context,
      title: 'Add a photo',
      actions: const [
        AppSheetAction(
          icon: Symbols.photo_camera,
          label: 'Take a photo',
          value: ImageSource.camera,
        ),
        AppSheetAction(
          icon: Symbols.photo_library,
          label: 'Choose from gallery',
          value: ImageSource.gallery,
        ),
      ],
    );
    if (source == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final photo = await ref
          .read(postMediaServiceProvider)
          .pickWorkoutPhoto(source: source);
      if (mounted && photo != null) {
        setState(() {
          _selectedPhoto = photo;
          _imagePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't attach photo: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _shareWorkout() async {
    setState(() => _isSharing = true);
    final content = _captionCtrl.text.trim();
    try {
      await ref.read(apiClientProvider).ensureFreshToken();
      final sync = ref.read(syncServiceProvider);

      // Sync session + sets to the server before uploading a photo or sharing.
      String? resolvedServerId;
      if (await checkIsOnline()) {
        resolvedServerId =
            await sync.ensureSessionReadyForShare(widget.sessionId);
      }

      if (_selectedPhoto != null && _imagePath == null) {
        final imagePath = await ref
            .read(postMediaServiceProvider)
            .uploadWorkoutPhoto(_selectedPhoto!);
        if (mounted) setState(() => _imagePath = imagePath);
      }
      if (resolvedServerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                await checkIsOnline()
                    ? 'Workout saved locally. It will share once sync completes.'
                    : 'Workout saved offline. It will share when you reconnect.',
              ),
            ),
          );
        }
        await PendingWorkoutShareQueue(ref.read(appDatabaseProvider)).enqueue(
          sessionId: widget.sessionId,
          content: content,
          imagePath: _imagePath,
        );
        if (mounted) setState(() => _isQueued = true);
        return;
      }

      final confirmedServerId = resolvedServerId;
      final post = await ref
          .read(socialServiceProvider)
          .shareWorkout(
            sessionId: confirmedServerId,
            content: content,
            imagePath: _imagePath,
          );
      ref.read(feedProvider.notifier).prependPost(post);
      if (mounted) setState(() => _isShared = true);
    } on DioException catch (e) {
      debugPrint('[WorkoutCompleteScreen] share failed: $e');
      final status = e.response?.statusCode;
      if (_selectedPhoto != null && _imagePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The photo could not be uploaded. Check your connection and retry.',
              ),
            ),
          );
        }
        return;
      }
      if (mounted) {
        final message = status == 429
            ? 'Too many shares recently. Wait a bit and try again.'
            : status == 404
                ? 'Workout is still syncing. Try again in a few seconds.'
                : e.type == DioExceptionType.receiveTimeout ||
                        e.type == DioExceptionType.connectionTimeout
                    ? 'The server took too long. Your share was queued — try Feed again shortly.'
                    : 'Could not share right now. Your workout was queued to retry.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      // Don't queue rate-limited shares — retrying would hit the same cap.
      if (status == 429) return;
      await PendingWorkoutShareQueue(ref.read(appDatabaseProvider)).enqueue(
        sessionId: widget.sessionId,
        content: content,
        imagePath: _imagePath,
      );
      if (mounted) setState(() => _isQueued = true);
    } catch (e) {
      debugPrint('[WorkoutCompleteScreen] share failed: $e');
      if (_selectedPhoto != null && _imagePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The photo could not be uploaded. Check your connection and retry.',
              ),
            ),
          );
        }
        return;
      }
      await PendingWorkoutShareQueue(ref.read(appDatabaseProvider)).enqueue(
        sessionId: widget.sessionId,
        content: content,
        imagePath: _imagePath,
      );
      if (mounted) {
        setState(() => _isQueued = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not share right now. Your workout was queued to retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day} ${_monthName(now.month)} ${now.year}, ${_formatTime(now)}';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Save Workout'),
        actions: [
          if (!_isShared && !_isQueued)
            TextButton(
              onPressed: _isSharing ? null : _shareWorkout,
              child: Text(
                _isSharing ? 'Saving...' : 'Save',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                decoration: InputDecoration(
                  hintText: 'Workout name',
                  border: InputBorder.none,
                  suffixIcon: _titleCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () => setState(() => _titleCtrl.clear()),
                          icon: const Icon(Symbols.close, size: 18),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SaveStat(
                    label: 'Duration',
                    value: _formatDuration(widget.duration),
                    highlight: true,
                  ),
                  _SaveStat(
                    label: 'Volume',
                    value: '${widget.totalVolume.toStringAsFixed(0)} kg',
                  ),
                  _SaveStat(
                    label: 'Sets',
                    value: '${widget.totalSets}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isShared && !_isQueued) ...[
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickPhoto,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _selectedPhoto != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXl),
                            child: Image.file(
                              File(_selectedPhoto!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.add_photo_alternate,
                                size: 32,
                                color: AppTheme.onSurfaceVariant
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isUploadingPhoto
                                    ? 'Attaching photo...'
                                    : 'Add a photo',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionCtrl,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'How did your workout go? Leave some notes here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _SaveSettingRow(
                  icon: Symbols.calendar_today,
                  label: 'Date',
                  value: dateLabel,
                ),
                const Divider(height: 24),
                _SaveSettingRow(
                  icon: Symbols.visibility,
                  label: 'Visibility',
                  value: 'Gym members & coaches',
                ),
              ],
              if (widget.prCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(
                      color: AppTheme.primaryContainer.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '${widget.prCount} new personal record${widget.prCount > 1 ? 's' : ''}!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryContainer,
                        ),
                  ),
                ),
              ],
              if (_isShared || _isQueued) ...[
                const SizedBox(height: 16),
                Text(
                  _isShared
                      ? 'Workout shared with your gym.'
                      : 'Workout saved — it will appear in the feed once sync finishes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryContainer,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_isShared && !_isQueued)
                SecondaryButton(
                  label: _isSharing ? 'Sharing...' : 'Share with Gym',
                  icon: Symbols.share,
                  onPressed: _isSharing ? null : _shareWorkout,
                ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _isShared || _isQueued ? 'Done' : 'Skip & Finish',
                icon: Symbols.check,
                onPressed: () {
                  ref.invalidate(homeDataProvider);
                  ref.invalidate(feedProvider);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _SaveStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SaveStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: highlight
                      ? AppTheme.primaryContainer
                      : AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SaveSettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SaveSettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
