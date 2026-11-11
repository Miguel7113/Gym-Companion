import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tether_palette.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/navigation/main_navigation.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import '../widgets/hevy_exercise_card.dart'; // For DraftSetEntry
import '../../home/providers/home_data_provider.dart';
import 'exercise_picker_sheet.dart';
import 'exercise_picker_sheet.dart';
import 'workout_session_screen.dart'; // For WorkoutCompleteScreen

/// Phase 2: Redesigned workout session screen with full state management
/// Matches Tether redesign reference with integrated functionality
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final WorkoutSession? session;
  final List<BuilderExerciseEntry>? builderExercises;

  const WorkoutSessionScreen({
    super.key,
    this.session,
    this.builderExercises,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState
    extends ConsumerState<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  // ── Session state ──────────────────────────────────────────────────────────
  WorkoutSession? _session;
  bool _isCreating = false;
  bool _isEnding = false;
  String? _error;

  // ── Sets (local mirror) ────────────────────────────────────────────────────
  final Map<String, List<_LocalSet>> _setsByExercise = {};
  final List<String> _exerciseOrder = [];
  final Map<String, Exercise> _exerciseMap = {};
  final Map<String, List<DraftSetEntry>> _draftSetsByExercise = {};
  final Map<String, ProgressData?> _previousByExercise = {};
  final Map<String, bool> _restEnabledByExercise = {};
  final Map<String, String> _notesByExercise = {};
  int _prCount = 0;
  String? _lastPrExerciseName;
  String? _lastPrValue;

  // ── Elapsed timer ──────────────────────────────────────────────────────────
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // ── Rest timer ─────────────────────────────────────────────────────────────
  int _restDurationSecs = 90;
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _restActive = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  final Set<String> _expandedExercises = {}; // Track by exerciseId
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
      
      // Pre-populate from builder exercises
      if (widget.builderExercises != null) {
        for (final entry in widget.builderExercises!) {
          final id = entry.exercise.id;
          if (!_setsByExercise.containsKey(id)) {
            _setsByExercise[id] = [];
            _exerciseOrder.add(id);
            _exerciseMap[id] = entry.exercise;
            _expandedExercises.add(id); // Auto-expand planned exercises
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
      // Auto-expand first exercise if none are expanded
      if (_expandedExercises.isEmpty && _exerciseOrder.isNotEmpty) {
        _expandedExercises.add(_exerciseOrder.first);
      }
    } else {
      // Show name dialog after first frame
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
    if (_session == null || _isEnding) return;
    
    // Show confirmation dialog
    final confirmed = await _showEndConfirm();
    if (!confirmed || !mounted) return;

    // Stop timers and flush any filled drafts
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
      
      // Invalidate home data to remove "in progress" card
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
              totalSets: _totalSets,
              exerciseCount: _exerciseOrder.length,
              prCount: _prCount,
              totalVolume: _totalVolumeKg,
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

  Future<void> _pickExercise() async {
      await ExercisePickerSheet.show(
        context,
        onExerciseSelected: _addExercise,
      );
    } else {
      await ExercisePickerSheet.show(
        context,
        onExerciseSelected: _addExercise,
      );
    }
  }

  void _addExercise(Exercise ex) {
    setState(() {
      if (!_exerciseOrder.contains(ex.id)) {
        _exerciseOrder.add(ex.id);
        _exerciseMap[ex.id] = ex;
        _setsByExercise[ex.id] = [];
        _draftSetsByExercise[ex.id] = [DraftSetEntry.empty()];
        _expandedExercises.add(ex.id); // Auto-expand new exercise
        _loadPreviousForExercise(ex.id);
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't remove all sets. Check your connection and try again."),
          ),
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
      _expandedExercises.remove(exerciseId);
    });
  }

  void _showExerciseMenu(String exerciseId) {
    showAppActionSheet(
      context,
      title: _exerciseMap[exerciseId]?.name ?? 'Exercise',
      actions: [
        AppSheetAction(
          icon: Symbols.delete,
          label: 'Remove exercise',
          value: 'remove',
        ),
      ],
    ).then((action) {
      if (action == 'remove') {
        _removeExercise(exerciseId);
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
        _prBannerCtrl.forward(from: 0);
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      if (!mounted) return;
      setState(() {
        final drafts = _draftSetsByExercise[exerciseId];
        drafts?.remove(draft);
        
        // If no drafts left, create new draft with same weight/reps
        if (drafts != null && drafts.isEmpty) {
          drafts.add(DraftSetEntry(
            localId: '${exerciseId}_${DateTime.now().millisecondsSinceEpoch}',
            weightKg: weight,
            reps: reps,
          ));
        } else if (drafts != null && drafts.isNotEmpty) {
          // Duplicate weight/reps to next draft set
          final nextDraft = drafts.first;
          nextDraft.weightKg = weight;
          nextDraft.reps = reps;
        }
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

  void _addRestTime(int seconds) {
    setState(() {
      _restRemaining += seconds;
      if (_restRemaining < 0) _restRemaining = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    // Loading state
    if (_isCreating || _session == null) {
      return Scaffold(
        backgroundColor: TetherTokens.ink,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(p.accent),
          ),
        ),
      );
    }

    final isCompleted = _session!.endedAt != null;
    final workoutName = _session!.notes?.isNotEmpty == true
        ? _session!.notes!
        : 'Workout';

    return Scaffold(
      backgroundColor: TetherTokens.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(p, workoutName, isCompleted),
            
            // Stats bar
            _buildStatsBar(p),
            
            const SizedBox(height: 16),
            
            // Error banner
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildErrorBanner(_error!),
              ),
            
            if (_error != null)
              const SizedBox(height: 16),
            
            // PR Banner
            if (_prCount > 0 && _prBannerCtrl.value > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _prBannerCtrl,
                    curve: Curves.elasticOut,
                  ),
                  child: _buildPrBanner(p),
                ),
              ),
            
            if (_prCount > 0 && _prBannerCtrl.value > 0)
              const SizedBox(height: 16),
            
            // Exercise list
            Expanded(
              child: _exerciseOrder.isEmpty
                  ? _buildEmptyState(p)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _exerciseOrder.length,
                      itemBuilder: (context, index) {
                        final exerciseId = _exerciseOrder[index];
                        final exercise = _exerciseMap[exerciseId];
                        if (exercise == null) return const SizedBox.shrink();
                        
                        final logged = _setsByExercise[exerciseId] ?? [];
                        final drafts = _draftSetsByExercise[exerciseId] ?? [];
                        final previous = _previousByExercise[exerciseId];
                        
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: index == _exerciseOrder.length - 1 ? 0 : 0,
                          ),
                          child: _buildExerciseCard(
                            p,
                            exerciseId: exerciseId,
                            exercise: exercise,
                            logged: logged,
                            drafts: drafts,
                            previous: previous,
                            isCompleted: isCompleted,
                          ),
                        );
                      },
                    ),
            ),
            
            // Bottom padding for FAB
            if (!isCompleted) const SizedBox(height: 80),
          ],
        ),
      ),
      // Add exercise button (only if not completed)
      floatingActionButton: isCompleted
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _pickExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: TetherTokens.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TetherTokens.rPill),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: TetherTokens.ink),
                      const SizedBox(width: 8),
                      Text(
                        'Add exercise',
                        style: TetherText.sans(
                          16,
                          w: TetherTokens.w600,
                          color: TetherTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // Rest timer bottom sheet
      bottomSheet: _restActive ? _buildRestTimerSheet(p) : null,
    );
  }

  Widget _buildEmptyState(TetherPalette p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: TetherTokens.cream.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: TetherText.sans(
              18,
              w: TetherTokens.w600,
              color: TetherTokens.cream.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add exercise" to get started',
            style: TetherText.sans(
              14,
              color: TetherTokens.cream.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TetherPalette p, String workoutName, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: TetherTokens.cream,
              size: 32,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Workout name (centered)
          Expanded(
            child: Center(
              child: Text(
                workoutName,
                style: TetherText.sans(28, color: TetherTokens.cream, w: TetherTokens.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Finish button (only if not completed)
          if (!isCompleted)
            GestureDetector(
              onTap: _endSession,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(TetherTokens.rPill),
                ),
                child: Center(
                  child: Text(
                    'Finish',
                    style: TetherText.sans(
                      15,
                      w: TetherTokens.w600,
                      color: TetherTokens.ink,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 44), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildStatsBar(TetherPalette p) {
    final elapsed = _formatElapsed(_elapsed);
    final volumeKg = _totalVolumeKg.round();
    final setsCompleted = _totalSets;
    final totalPlannedSets = _exerciseOrder.fold<int>(
      0,
      (sum, id) {
        final completed = _setsByExercise[id]?.length ?? 0;
        final drafts = _draftSetsByExercise[id]?.length ?? 0;
        return sum + completed + drafts;
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // TIME
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIME',
                style: TetherText.label(
                  11,
                  TetherTokens.cream.withOpacity(0.5),
                  ls: 0.88,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                elapsed,
                style: TetherText.numeral(44, p.accent),
              ),
            ],
          ),
          
          // VOLUME
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOLUME',
                style: TetherText.label(
                  11,
                  TetherTokens.cream.withOpacity(0.5),
                  ls: 0.88,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: '$volumeKg',
                  style: TetherText.numeral(30, TetherTokens.cream),
                  children: [
                    TextSpan(
                      text: ' kg',
                      style: TetherText.sans(
                        14,
                        color: TetherTokens.cream.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // SETS
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETS',
                style: TetherText.label(
                  11,
                  TetherTokens.cream.withOpacity(0.5),
                  ls: 0.88,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: '$setsCompleted',
                  style: TetherText.numeral(30, TetherTokens.cream),
                  children: [
                    if (totalPlannedSets > setsCompleted)
                      TextSpan(
                        text: ' / $totalPlannedSets',
                        style: TetherText.sans(
                          14,
                          color: TetherTokens.cream.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    TetherPalette p, {
    required String exerciseId,
    required Exercise exercise,
    required List<_LocalSet> logged,
    required List<DraftSetEntry> drafts,
    required ProgressData? previous,
    required bool isCompleted,
  }) {
    final isExpanded = _expandedExercises.contains(exerciseId);
    final completedCount = logged.length;
    final totalCount = logged.length + drafts.length;
    final muscles = exercise.bodyParts.isNotEmpty 
        ? exercise.bodyParts.join(', ') 
        : 'Exercise';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedExercises.remove(exerciseId);
          } else {
            _expandedExercises.add(exerciseId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TetherTokens.nightCard,
          borderRadius: BorderRadius.circular(TetherTokens.rCard),
        ),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                // Exercise image placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: TetherTokens.nightRaised,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      exercise.name.substring(0, 1).toUpperCase(),
                      style: TetherText.sans(
                        20,
                        w: TetherTokens.w600,
                        color: p.accent,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TetherText.sans(
                          18,
                          w: TetherTokens.w600,
                          color: TetherTokens.cream,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isExpanded 
                            ? muscles 
                            : '$completedCount of $totalCount sets',
                        style: TetherText.sans(
                          13,
                          color: TetherTokens.cream.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu button
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: TetherTokens.cream.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: isCompleted ? null : () => _showExerciseMenu(exerciseId),
                ),
              ],
            ),
            
            // Expanded set table
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _buildSetTable(p, exerciseId, logged, drafts, previous, isCompleted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetTable(
    TetherPalette p,
    String exerciseId,
    List<_LocalSet> logged,
    List<DraftSetEntry> drafts,
    ProgressData? previous,
    bool isCompleted,
  ) {
    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'SET',
                  style: TetherText.label(
                    10,
                    TetherTokens.cream.withOpacity(0.4),
                    ls: 0.6,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'PREVIOUS',
                  style: TetherText.label(
                    10,
                    TetherTokens.cream.withOpacity(0.4),
                    ls: 0.6,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'KG',
                  style: TetherText.label(
                    10,
                    TetherTokens.cream.withOpacity(0.4),
                    ls: 0.6,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'REPS',
                  style: TetherText.label(
                    10,
                    TetherTokens.cream.withOpacity(0.4),
                    ls: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Logged sets (completed)
        ...logged.asMap().entries.map((entry) {
          final setNum = entry.key + 1;
          final set = entry.value;
          return _buildCompletedSetRow(p, setNum, set);
        }),
        
        // Draft sets (not yet completed)
        if (!isCompleted)
          ...drafts.asMap().entries.map((entry) {
            final setNum = logged.length + entry.key + 1;
            final draft = entry.value;
            final previousForSet = previous; // TODO: Show previous for this specific set number
            return _buildDraftSetRow(p, exerciseId, setNum, draft, previousForSet);
          }),
        
        // Add set button
        if (!isCompleted) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _addDraftSet(exerciseId),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: TetherTokens.cream.withOpacity(0.2),
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '+ Add set',
                  style: TetherText.sans(
                    14,
                    w: TetherTokens.w600,
                    color: TetherTokens.cream.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedSetRow(TetherPalette p, int setNum, _LocalSet set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 40,
            child: Text(
              '$setNum',
              style: TetherText.sans(
                16,
                w: TetherTokens.w600,
                color: TetherTokens.cream.withOpacity(0.7),
              ),
            ),
          ),
          
          // Previous (empty for completed sets)
          const Expanded(child: SizedBox()),
          
          // KG (display only)
          Container(
            width: 70,
            height: 40,
            decoration: BoxDecoration(
              color: TetherTokens.nightRaised,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${set.weightKg.toStringAsFixed(set.weightKg == set.weightKg.round() ? 0 : 1)}',
                style: TetherText.sans(
                  16,
                  w: TetherTokens.w600,
                  color: TetherTokens.cream,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // REPS (display only)
          Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: TetherTokens.nightRaised,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${set.reps}',
                style: TetherText.sans(
                  16,
                  w: TetherTokens.w600,
                  color: TetherTokens.cream,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Check (completed)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: TetherTokens.ink,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftSetRow(
    TetherPalette p,
    String exerciseId,
    int setNum,
    DraftSetEntry draft,
    ProgressData? previous,
  ) {
    final weightController = TextEditingController(
      text: draft.weightKg > 0 ? draft.weightKg.toStringAsFixed(draft.weightKg == draft.weightKg.round() ? 0 : 1) : '',
    );
    final repsController = TextEditingController(
      text: draft.reps > 0 ? '${draft.reps}' : '',
    );
    
    final previousText = previous != null 
        ? '${previous.weightKg!.toStringAsFixed(0)} kg × ${previous.reps}' 
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 40,
            child: Text(
              '$setNum',
              style: TetherText.sans(
                16,
                w: TetherTokens.w600,
                color: TetherTokens.cream.withOpacity(0.7),
              ),
            ),
          ),
          
          // Previous
          Expanded(
            child: Text(
              previousText,
              style: TetherText.sans(
                13,
                color: TetherTokens.cream.withOpacity(0.4),
              ),
            ),
          ),
          
          // KG input
          SizedBox(
            width: 70,
            child: TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TetherText.sans(
                16,
                w: TetherTokens.w600,
                color: TetherTokens.cream,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: TetherTokens.nightRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                hintText: '0',
                hintStyle: TetherText.sans(
                  16,
                  color: TetherTokens.cream.withOpacity(0.3),
                ),
              ),
              onChanged: (value) {
                final kg = double.tryParse(value) ?? 0;
                final draftList = _draftSetsByExercise[exerciseId];
                if (draftList != null) {
                  final draftItem = draftList.firstWhere(
                    (d) => d.localId == draft.localId,
                    orElse: () => draft,
                  );
                  draftItem.weightKg = kg;
                }
              },
            ),
          ),
          
          const SizedBox(width: 10),
          
          // REPS input
          SizedBox(
            width: 50,
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TetherText.sans(
                16,
                w: TetherTokens.w600,
                color: TetherTokens.cream,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: TetherTokens.nightRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                hintText: '0',
                hintStyle: TetherText.sans(
                  16,
                  color: TetherTokens.cream.withOpacity(0.3),
                ),
              ),
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                final draftList = _draftSetsByExercise[exerciseId];
                if (draftList != null) {
                  final draftItem = draftList.firstWhere(
                    (d) => d.localId == draft.localId,
                    orElse: () => draft,
                  );
                  draftItem.reps = reps;
                }
              },
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Check button
          GestureDetector(
            onTap: () {
              final weight = double.tryParse(weightController.text) ?? 0;
              final reps = int.tryParse(repsController.text) ?? 0;
              if (weight > 0 && reps > 0) {
                _completeDraftSet(exerciseId, draft, weight, reps, null);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TetherTokens.nightRaised,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: TetherTokens.cream.withOpacity(0.3),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerSheet(TetherPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: TetherTokens.cream,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TetherTokens.rSheet),
        ),
      ),
      child: Row(
        children: [
          // Timer display
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REST',
                style: TetherText.label(
                  11,
                  TetherTokens.ink.withOpacity(0.5),
                  ls: 0.88,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatRestTime(_restRemaining),
                style: TetherText.numeral(36, TetherTokens.ink),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // - button
          _buildTimerButton(
            icon: Icons.remove_rounded,
            onPressed: () => _addRestTime(-15),
          ),
          
          const SizedBox(width: 12),
          
          // + button
          _buildTimerButton(
            icon: Icons.add_rounded,
            onPressed: () => _addRestTime(15),
          ),
          
          const Spacer(),
          
          // Skip button
          GestureDetector(
            onTap: _dismissRest,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: TetherTokens.ink,
                borderRadius: BorderRadius.circular(TetherTokens.rPill),
              ),
              child: Center(
                child: Text(
                  'Skip',
                  style: TetherText.sans(
                    15,
                    w: TetherTokens.w600,
                    color: TetherTokens.cream,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TetherTokens.ink.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: TetherTokens.ink),
        onPressed: onPressed,
      ),
    );
  }

  String _formatRestTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildPrBanner(TetherPalette p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(TetherTokens.rCard),
        border: Border.all(color: p.accent.withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(TetherTokens.rPill),
            ),
            child: Text(
              'PR',
              style: TetherText.sans(
                12,
                w: TetherTokens.w800,
                color: TetherTokens.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prCount == 1
                      ? 'New personal record!'
                      : '$_prCount personal records this session!',
                  style: TetherText.sans(
                    16,
                    w: TetherTokens.w600,
                    color: p.accent,
                  ),
                ),
                if (_lastPrExerciseName != null && _lastPrValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$_lastPrExerciseName: $_lastPrValue',
                    style: TetherText.sans(
                      13,
                      color: TetherTokens.cream.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.15),
        borderRadius: BorderRadius.circular(TetherTokens.rCard),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFE53935),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TetherText.sans(
                14,
                color: TetherTokens.cream.withOpacity(0.9),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: TetherTokens.cream.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }
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


// ─────────────────────────────────────────────────────────────────────────────
// End Workout Dialog
// ─────────────────────────────────────────────────────────────────────────────
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
