import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import '../../social/providers/feed_provider.dart';
import '../../social/services/social_service.dart';
import 'exercise_picker_sheet.dart';

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

  const WorkoutSessionScreen({
    super.key,
    this.session,
    this.builderExercises,
  });

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

  // ── Add-set form ───────────────────────────────────────────────────────────
  Exercise? _selectedExercise;
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _rpeCtrl = TextEditingController();
  bool _isSavingSet = false;
  String? _setError;

  // ── "Last time" hint ───────────────────────────────────────────────────────
  ProgressData? _lastTimeHint;
  bool _loadingHint = false;

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
          if (!_setsByExercise.containsKey(entry.exercise.id)) {
            _setsByExercise[entry.exercise.id] = [];
            _exerciseOrder.add(entry.exercise.id);
            // Store exercise ref so we can look it up later
            _exerciseMap[entry.exercise.id] = entry.exercise;
          }
        }
      }
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
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _rpeCtrl.dispose();
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
  }

  void _startElapsedTimer() {
    if (_session == null) return;
    final start = _session!.startedAt;
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
    final result = await showDialog<String>(
      context: context,
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
    setState(() { _isCreating = true; _error = null; });
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

    setState(() { _isEnding = true; _error = null; });
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      await svc.endSession(_session!.id, notes: _session!.notes);
      _elapsedTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutCompleteScreen(
              duration: _elapsed,
              totalSets: _setsByExercise.values
                  .fold(0, (sum, sets) => sum + sets.length),
              exerciseCount: _exerciseOrder.length,
              prCount: _prCount,
              workoutName: _session!.notes,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] endSession failed: $e');
      setState(() {
        _isEnding = false;
        _error = "Couldn't save workout";
      });
    }
  }

  Future<bool> _showEndConfirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _EndWorkoutDialog(
            duration: _formatElapsed(_elapsed),
            setCount: _setsByExercise.values
                .fold(0, (sum, sets) => sum + sets.length),
          ),
        ) ??
        false;
  }

  // ─── Exercise picker ─────────────────────────────────────────────────────────

  Future<void> _pickExercise() async {
    await ExercisePickerSheet.show(
      context,
      onExerciseSelected: (ex) {
        setState(() { _selectedExercise = ex; });
        _loadLastTimeHint(ex.id);
      },
    );
  }

  Future<void> _loadLastTimeHint(String exerciseId) async {
    setState(() { _loadingHint = true; _lastTimeHint = null; });
    try {
      final svc = ref.read(workoutServiceProvider);
      final history = await svc.getProgress(exerciseId);
      if (mounted) {
        setState(() {
          _lastTimeHint = history.isNotEmpty ? history.last : null;
          _loadingHint = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHint = false);
    }
  }

  // ─── Add set ─────────────────────────────────────────────────────────────────

  Future<void> _addSet() async {
    if (_selectedExercise == null) {
      setState(() => _setError = 'Select an exercise first');
      return;
    }
    if (_session == null) return;

    final weight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);
    final rpe = double.tryParse(_rpeCtrl.text);

    if (weight == null || reps == null) {
      setState(() => _setError = 'Enter weight and reps');
      return;
    }

    setState(() { _isSavingSet = true; _setError = null; });

    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final ex = _selectedExercise!;
      final setNum = (_setsByExercise[ex.id]?.length ?? 0) + 1;

      final result = await svc.addSet(
        _session!.id,
        exerciseId: ex.id,
        setNumber: setNum,
        reps: reps,
        weightKg: weight,
        rpe: rpe,
      );

      // Mirror into local state
      if (!_setsByExercise.containsKey(ex.id)) {
        _setsByExercise[ex.id] = [];
        _exerciseOrder.add(ex.id);
        _exerciseMap[ex.id] = ex;
      }
      _setsByExercise[ex.id]!.add(_LocalSet(
        id: result.set.id,
        exercise: ex,
        setNumber: setNum,
        weightKg: weight,
        reps: reps,
        rpe: rpe,
        isPr: result.isPr,
      ));

      if (result.isPr) {
        _prCount++;
        _lastPrExerciseName = ex.name;
        _lastPrValue = '${weight}kg × $reps reps';
        // Pick image based on body part
        final bodyPart = ex.bodyParts.isNotEmpty ? ex.bodyParts.first : null;
        _lastPrImageUrl = _prImageForBodyPart(bodyPart);
        _prBannerCtrl.forward(from: 0);
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      // Clear form, keep exercise selected for quick multi-set logging
      _weightCtrl.clear();
      _repsCtrl.clear();
      _rpeCtrl.clear();

      // Auto-start rest timer
      _startRestTimer();

      setState(() => _isSavingSet = false);
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] addSet failed: $e');
      setState(() {
        _isSavingSet = false;
        _setError = "Couldn't save set";
      });
    }
  }

  Future<void> _deleteSet(String setId, String exerciseId) async {
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      await svc.deleteSet(setId);
      setState(() {
        _setsByExercise[exerciseId]?.removeWhere((s) => s.id == setId);
        if (_setsByExercise[exerciseId]?.isEmpty == true) {
          _setsByExercise.remove(exerciseId);
          _exerciseOrder.remove(exerciseId);
          _exerciseMap.remove(exerciseId);
        }
      });
    } catch (e) {
      debugPrint('[WorkoutSessionScreen] deleteSet failed: $e');
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
      if (!mounted) { t.cancel(); return; }
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
        )),
      );
    }

    if (_session == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: _error != null
          ? ConnectErrorState(onRetry: () => _showNameDialog())
          : const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryContainer),
            ),
        ),
      );
    }

    return Scaffold(
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
                ),
              ),

              // Error banner
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.containerMargin, 12,
                        AppTheme.containerMargin, 0),
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
                            AppTheme.containerMargin, 12,
                            AppTheme.containerMargin, 0),
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

              // Set tables (one per exercise)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.containerMargin, AppTheme.stackMd,
                  AppTheme.containerMargin, 0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final exerciseId = _exerciseOrder[i];
                      final sets = _setsByExercise[exerciseId] ?? [];
                      final exerciseName =
                          _exerciseMap[exerciseId]?.name ??
                          sets.firstOrNull?.exercise.name ??
                          'Exercise';
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppTheme.stackSm),
                        child: _ExerciseSetTable(
                          exerciseName: exerciseName,
                          sets: sets,
                          onDeleteSet: (setId) =>
                              _deleteSet(setId, exerciseId),
                        ),
                      );
                    },
                    childCount: _exerciseOrder.length,
                  ),
                ),
              ),

              // Empty state
              if (_exerciseOrder.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.containerMargin, AppTheme.stackLg,
                      AppTheme.containerMargin, 0,
                    ),
                    child: _EmptySessionState(),
                  ),
                ),

              // Add-set form
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.containerMargin, AppTheme.stackMd,
                    AppTheme.containerMargin, 120,
                  ),
                  child: _AddSetForm(
                    selectedExercise: _selectedExercise,
                    weightCtrl: _weightCtrl,
                    repsCtrl: _repsCtrl,
                    rpeCtrl: _rpeCtrl,
                    isSaving: _isSavingSet,
                    error: _setError,
                    lastTimeHint: _lastTimeHint,
                    loadingHint: _loadingHint,
                    onPickExercise: _pickExercise,
                    onAddSet: _addSet,
                  ),
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
                onAdjust: (secs) => setState(() =>
                    _restDurationSecs = secs),
              ),
            ),
        ],
      ),
    );
  }
}

String _prImageForBodyPart(String? bodyPart) {
  const map = {
    'chest': 'https://images.unsplash.com/photo-1534368786749-b63e05c92717?w=800&q=80',
    'back': 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=80',
    'upper arms': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
    'shoulders': 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=80',
    'upper legs': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
    'lower legs': 'https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=800&q=80',
    'waist': 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80',
    'cardio': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=80',
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
    exercise: s.exercise ?? Exercise(id: s.exerciseId, name: 'Exercise',
        isCustom: false),
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

  const _SessionHeaderDelegate({
    required this.session,
    required this.elapsed,
    required this.isEnding,
    required this.onEnd,
  });

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  bool shouldRebuild(_SessionHeaderDelegate old) =>
      elapsed != old.elapsed || isEnding != old.isEnding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: AppTheme.containerMargin,
        right: AppTheme.containerMargin,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Symbols.arrow_back, size: 18,
                  color: AppTheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          // Workout name + timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (session.notes?.isNotEmpty == true)
                      ? session.notes!
                      : 'Workout Session',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.neonGlow(opacity: 0.6, blur: 8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      elapsed,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // End workout button
          GestureDetector(
            onTap: isEnding ? null : onEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: AppTheme.neonGlow(opacity: 0.3),
              ),
              child: isEnding
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.onPrimaryFixed),
                    ),
                  )
                : Text(
                    'FINISH',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.onPrimaryFixed,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExerciseSetTable — one card per exercise with all logged sets
// ─────────────────────────────────────────────────────────────────────────────
class _ExerciseSetTable extends StatelessWidget {
  final String exerciseName;
  final List<_LocalSet> sets;
  final void Function(String setId) onDeleteSet;

  const _ExerciseSetTable({
    required this.exerciseName,
    required this.sets,
    required this.onDeleteSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              exerciseName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TableHeader('SET', flex: 1),
                _TableHeader('KG', flex: 2),
                _TableHeader('REPS', flex: 2),
                _TableHeader('RPE', flex: 2),
                const SizedBox(width: 32), // delete button column
              ],
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          // Set rows
          ...sets.map((s) => _SetRow(set: s, onDelete: () => onDeleteSet(s.id))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _TableHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final _LocalSet set;
  final VoidCallback onDelete;
  const _SetRow({required this.set, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: set.isPr
        ? BoxDecoration(
            color: AppTheme.primaryContainer.withOpacity(0.06),
            border: Border(
              left: BorderSide(color: AppTheme.primaryContainer, width: 2),
            ),
          )
        : null,
      child: Row(
        children: [
          // Set number
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Text(
                  '${set.setNumber}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (set.isPr) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: AppTheme.neonGlow(opacity: 0.4, blur: 8),
                    ),
                    child: Text(
                      'PR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onPrimaryFixed,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('${set.weightKg}',
            style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(flex: 2, child: Text('${set.reps}',
            style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(flex: 2, child: Text(
            set.rpe != null ? '${set.rpe}' : '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: set.rpe != null
                  ? AppTheme.onSurface
                  : AppTheme.onSurfaceVariant,
            ),
          )),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Symbols.close, size: 14, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddSetForm — exercise picker + weight/reps/RPE inputs + last-time hint
// ─────────────────────────────────────────────────────────────────────────────
class _AddSetForm extends StatelessWidget {
  final Exercise? selectedExercise;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController rpeCtrl;
  final bool isSaving;
  final String? error;
  final ProgressData? lastTimeHint;
  final bool loadingHint;
  final VoidCallback onPickExercise;
  final VoidCallback onAddSet;

  const _AddSetForm({
    required this.selectedExercise,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.rpeCtrl,
    required this.isSaving,
    required this.error,
    required this.lastTimeHint,
    required this.loadingHint,
    required this.onPickExercise,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.2)),
        boxShadow: AppTheme.neonGlow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOG A SET',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryContainer,
            ),
          ),
          const SizedBox(height: AppTheme.stackSm),

          // Exercise picker
          GestureDetector(
            onTap: onPickExercise,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedExercise != null
                        ? Symbols.fitness_center
                        : Symbols.add,
                    size: 18,
                    color: selectedExercise != null
                        ? AppTheme.primaryContainer
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedExercise?.name ?? 'Choose exercise',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selectedExercise != null
                            ? AppTheme.onSurface
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(Symbols.chevron_right, size: 18,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                ],
              ),
            ),
          ),

          // Last time hint
          if (loadingHint)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const SizedBox(width: 2, height: 2,
                  child: CircularProgressIndicator(strokeWidth: 1.5)),
                const SizedBox(width: 8),
                Text('Loading history...',
                  style: Theme.of(context).textTheme.labelSmall),
              ]),
            )
          else if (lastTimeHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Symbols.history, size: 13,
                    color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Last time: ${lastTimeHint!.weightKg}kg × ${lastTimeHint!.reps} reps',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ]),
            ),

          const SizedBox(height: AppTheme.stackSm),

          // Weight + Reps + RPE inputs
          Row(
            children: [
              Expanded(child: _SetInput(
                ctrl: weightCtrl, label: 'KG', hint: '0')),
              const SizedBox(width: 10),
              Expanded(child: _SetInput(
                ctrl: repsCtrl, label: 'REPS', hint: '0')),
              const SizedBox(width: 10),
              Expanded(child: _SetInput(
                ctrl: rpeCtrl, label: 'RPE', hint: '—', required: false)),
            ],
          ),

          if (error != null) ...[
            const SizedBox(height: 10),
            _InlineBanner(message: error!, isError: true),
          ],

          const SizedBox(height: AppTheme.stackSm),

          PrimaryButton(
            label: 'Add Set',
            icon: Symbols.add,
            isLoading: isSaving,
            onPressed: isSaving ? null : onAddSet,
          ),
        ],
      ),
    );
  }
}

class _SetInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;

  const _SetInput({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                color: AppTheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 12),
            ),
          ),
        ),
      ],
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
              const Icon(Symbols.timer, size: 16, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('REST',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // ─10s
              _AdjustButton(
                label: '−10',
                onTap: () => onAdjust(
                    (total - 10).clamp(10, 300)),
              ),
              const SizedBox(width: 8),
              // +10s
              _AdjustButton(
                label: '+10',
                onTap: () => onAdjust(
                    (total + 10).clamp(10, 300)),
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
                  child: const Icon(Symbols.close, size: 14,
                      color: AppTheme.onSurfaceVariant),
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
                remaining <= 10
                    ? AppTheme.error
                    : AppTheme.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Countdown
          Text(
            _display,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: remaining <= 10 ? AppTheme.error : AppTheme.primaryContainer,
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
        child: Text(label,
          style: Theme.of(context).textTheme.labelSmall),
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
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        side: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.stackMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NAME YOUR WORKOUT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text('Give it a name or start with a blank session',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.stackSm),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Push Day, Leg Day...',
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: AppTheme.stackMd),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppTheme.stackSm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Start',
                    icon: Symbols.play_arrow,
                    onPressed: () => Navigator.pop(context, controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EndWorkoutDialog extends StatelessWidget {
  final String duration;
  final int setCount;
  const _EndWorkoutDialog({required this.duration, required this.setCount});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        side: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.stackMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.primaryContainer.withOpacity(0.3)),
                boxShadow: AppTheme.neonGlow(opacity: 0.3),
              ),
              child: const Icon(Symbols.flag, size: 24,
                  color: AppTheme.primaryContainer),
            ),
            const SizedBox(height: AppTheme.stackSm),
            Text('FINISH WORKOUT?',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('$duration • $setCount sets logged',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.stackMd),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Keep Going',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: AppTheme.stackSm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Finish',
                    icon: Symbols.check,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _PrBanner extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: Text('PR',
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
          // Share to Feed button — only shown when we have PR details
          if (lastPrExerciseName != null && lastPrValue != null)
            GestureDetector(
              onTap: () => _sharePr(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                      color: AppTheme.primaryContainer.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.share, size: 13,
                        color: AppTheme.primaryContainer),
                    const SizedBox(width: 4),
                    Text('SHARE',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontSize: 10,
                      )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sharePr(BuildContext context, WidgetRef ref) async {
    try {
      final svc = ref.read(socialServiceProvider);
      final post = await svc.sharePrToFeed(
        exerciseName: lastPrExerciseName!,
        value: lastPrValue!,
        imageUrl: lastPrImageUrl ??
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
      );
      ref.read(feedProvider.notifier).prependPost(post);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PR shared to the feed!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not share — check your connection')),
        );
      }
    }
  }
}

class _EmptySessionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64, height: 64,
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
          'NO SETS YET',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose an exercise below and log your first set',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutCompleteScreen — post-workout summary
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutCompleteScreen extends StatelessWidget {
  final Duration duration;
  final int totalSets;
  final int exerciseCount;
  final int prCount;
  final String? workoutName;

  const WorkoutCompleteScreen({
    super.key,
    required this.duration,
    required this.totalSets,
    required this.exerciseCount,
    required this.prCount,
    this.workoutName,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Trophy icon
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryContainer.withOpacity(0.4),
                        width: 2),
                    boxShadow: AppTheme.neonGlow(opacity: 0.4, blur: 32),
                  ),
                  child: const Icon(Symbols.trophy, size: 36,
                      color: AppTheme.primaryContainer, fill: 1),
                ),
              ),
              const SizedBox(height: AppTheme.stackMd),
              // Title
              Text(
                'WORKOUT COMPLETE',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
              if (workoutName != null) ...[
                const SizedBox(height: 6),
                Text(
                  workoutName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppTheme.stackLg),
              // Stats bento
              Row(
                children: [
                  _SummaryTile(
                    value: _formatDuration(duration),
                    label: 'DURATION',
                    icon: Symbols.timer,
                  ),
                  const SizedBox(width: AppTheme.stackSm),
                  _SummaryTile(
                    value: '$totalSets',
                    label: 'SETS',
                    icon: Symbols.fitness_center,
                  ),
                  const SizedBox(width: AppTheme.stackSm),
                  _SummaryTile(
                    value: '$exerciseCount',
                    label: 'EXERCISES',
                    icon: Symbols.exercise,
                  ),
                ],
              ),
              if (prCount > 0) ...[
                const SizedBox(height: AppTheme.stackSm),
                Container(
                  padding: const EdgeInsets.all(AppTheme.stackSm),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                    border: Border.all(
                        color: AppTheme.primaryContainer.withOpacity(0.3)),
                    boxShadow: AppTheme.neonGlow(opacity: 0.15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text('PR',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.onPrimaryFixed)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$prCount new personal record${prCount > 1 ? 's' : ''}!',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.primaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Done',
                icon: Symbols.check,
                onPressed: () {
                  // Pop back to Train tab root
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppTheme.stackSm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryContainer),
            const SizedBox(height: 8),
            Text(value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
