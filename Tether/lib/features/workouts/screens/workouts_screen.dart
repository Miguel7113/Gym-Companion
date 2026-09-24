import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/media_catalog.dart';
import '../../../core/providers/nav_provider.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_service.dart';
import '../data/default_programs.dart';
import '../../social/screens/buddies_screen.dart';
import 'workout_builder_screen.dart';
import 'workout_session_screen.dart';
import 'routines_screen.dart';
import 'workout_history_screen.dart';
import 'exercise_picker_sheet.dart';
import 'progress_screen.dart';
import 'workout_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutsScreen — Train tab (Hevy-inspired hub)
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  int _selectedFilter = 0;
  final Set<String> _selectedEquipment = {};

  static const List<_Filter> _filters = [
    _Filter('All', null),
    _Filter('Strength', 'strength'),
    _Filter('Cardio', 'cardio'),
    _Filter('HIIT', 'hiit'),
    _Filter('Mobility', 'mobility'),
  ];

  List<String> _bodyParts = [];
  bool _loadingBodyParts = true;
  bool _bodyPartsError = false;
  WorkoutSession? _activeSession;
  List<WorkoutTemplate> _gymPrograms = [];
  bool _loadingGymPrograms = true;

  @override
  void initState() {
    super.initState();
    _loadBodyParts();
    _loadActiveSession();
    _loadGymPrograms();
  }

  Future<void> _loadGymPrograms() async {
    setState(() => _loadingGymPrograms = true);
    try {
      final programs =
          await ref.read(workoutServiceProvider).listGymPrograms();
      if (mounted) {
        setState(() {
          _gymPrograms = programs;
          _loadingGymPrograms = false;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] gym programs unavailable: $e');
      if (mounted) setState(() => _loadingGymPrograms = false);
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      final session =
          await ref.read(offlineWorkoutServiceProvider).getActiveSession();
      if (mounted) {
        setState(() {
          _activeSession =
              session != null && session.endedAt == null ? session : null;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] active session unavailable: $e');
    }
  }

  Future<void> _loadBodyParts() async {
    setState(() {
      _loadingBodyParts = true;
      _bodyPartsError = false;
    });
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final parts = await svc.listBodyParts();
      if (mounted) {
        setState(() {
          _bodyParts = parts;
          _loadingBodyParts = false;
          _bodyPartsError = parts.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('[WorkoutsScreen] _loadBodyParts failed: $e');
      if (mounted) {
        setState(() {
          _loadingBodyParts = false;
          _bodyPartsError = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadBodyParts(),
      _loadActiveSession(),
      _loadGymPrograms(),
    ]);
  }

  void _openExerciseList({String? bodyPart}) {
    final category = _filters[_selectedFilter].value;
    ExercisePickerSheet.show(
      context,
      onExerciseSelected: (_) {},
      initialBodyPart: bodyPart,
      initialCategory: category,
      initialEquipment: _selectedEquipment.isNotEmpty
          ? Set<String>.from(_selectedEquipment)
          : null,
    );
  }

  Future<void> _showEquipmentFilter() async {
    final svc = ref.read(offlineWorkoutServiceProvider);
    List<String> allEquipments = [];
    try {
      allEquipments = await svc.listEquipments();
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EquipmentGridFilter(
        allEquipments: allEquipments,
        selected: Set<String>.from(_selectedEquipment),
        onApply: (sel) => setState(() {
          _selectedEquipment
            ..clear()
            ..addAll(sel);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps Train mounted — re-check active session when the
    // tab becomes visible so Finish/Share cannot leave a phantom "Continue".
    ref.listen<int>(navIndexProvider, (prev, next) {
      if (next == NavTab.train && prev != null && prev != NavTab.train) {
        _loadActiveSession();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _TrainAppBar(
        onProgressTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surfaceContainerHigh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                8,
                AppTheme.containerMargin,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StartWorkoutPanel(
                    activeSession: _activeSession,
                    onStartBlank: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutBuilderScreen(),
                      ),
                    ).then((_) => _loadActiveSession()),
                    onContinue: _activeSession == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutSessionScreen(
                                  session: _activeSession,
                                ),
                              ),
                            ).then((_) => _loadActiveSession()),
                    onRoutines: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoutinesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.stackMd),
                  _QuickLinksRow(
                    onRoutines: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoutinesScreen(),
                      ),
                    ),
                    onExercises: () => _openExerciseList(),
                    onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: AppTheme.surface,
                          appBar: AppBar(
                            backgroundColor: AppTheme.surface,
                            elevation: 0,
                            title: const Text('History'),
                          ),
                          body: const WorkoutHistoryScreen(),
                        ),
                      ),
                    ),
                    onBuddies: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BuddiesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.stackLg),
                  if (_gymPrograms.isNotEmpty || _loadingGymPrograms) ...[
                    _SectionHeader(
                      title: 'Gym programs',
                      actionLabel: 'Routines',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoutinesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.stackSm),
                  ],
                ]),
              ),
            ),

            if (_gymPrograms.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 148,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.containerMargin,
                    ),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _gymPrograms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _GymProgramCard(
                      program: _gymPrograms[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutDetailScreen(routine: _gymPrograms[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                AppTheme.stackLg,
                AppTheme.containerMargin,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Programs'),
                  const SizedBox(height: AppTheme.stackSm),
                ]),
              ),
            ),

            // Programs horizontal list (edge-to-edge scroll)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 148,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.containerMargin,
                  ),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: defaultPrograms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) =>
                      _ProgramCard(program: defaultPrograms[i]),
                ),
              ),
            ),

            // Browse exercises
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                AppTheme.stackLg,
                AppTheme.containerMargin,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(
                    title: 'Browse exercises',
                    actionLabel: 'See all',
                    onAction: () => _openExerciseList(),
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                  Row(
                    children: [
                      _EquipmentChip(
                        selectedCount: _selectedEquipment.length,
                        onTap: _showEquipmentFilter,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChipRow(
                          filters: _filters,
                          selectedIndex: _selectedFilter,
                          onSelected: (i) {
                            setState(() => _selectedFilter = i);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _openExerciseList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                ]),
              ),
            ),

            if (_loadingBodyParts)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.containerMargin,
                ),
                sliver: SliverGrid(
                  gridDelegate: _muscleGridDelegate,
                  delegate: _SkeletonMuscleGridDelegate(count: 6),
                ),
              )
            else if (_bodyPartsError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.containerMargin,
                  ),
                  child: ConnectErrorState(onRetry: _loadBodyParts),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.containerMargin,
                ),
                sliver: SliverGrid(
                  gridDelegate: _muscleGridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _MuscleGroupTile(
                      bodyPart: _bodyParts[i],
                      onTap: () => _openExerciseList(bodyPart: _bodyParts[i]),
                    ),
                    childCount: _bodyParts.length,
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.containerMargin,
                AppTheme.stackLg,
                AppTheme.containerMargin,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionHeader(title: 'Recent workouts'),
                  const SizedBox(height: AppTheme.stackSm),
                  const SizedBox(height: 440, child: WorkoutHistoryScreen()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _muscleGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 1.4,
);

class _SkeletonMuscleGridDelegate extends SliverChildBuilderDelegate {
  _SkeletonMuscleGridDelegate({required int count})
      : super(
          (_, __) => const SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            radius: AppTheme.radiusXxl,
          ),
          childCount: count,
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _TrainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProgressTap;
  const _TrainAppBar({required this.onProgressTap});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppTheme.containerMargin,
      title: Text(
        'Train',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: onProgressTap,
            icon: const Icon(
              Symbols.bar_chart,
              size: 24,
              color: AppTheme.onSurface,
            ),
            tooltip: 'Progress',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Start workout hub — Hevy CTA hierarchy
// ─────────────────────────────────────────────────────────────────────────────
class _StartWorkoutPanel extends StatelessWidget {
  final WorkoutSession? activeSession;
  final VoidCallback onStartBlank;
  final VoidCallback? onContinue;
  final VoidCallback onRoutines;

  const _StartWorkoutPanel({
    required this.activeSession,
    required this.onStartBlank,
    required this.onContinue,
    required this.onRoutines,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeSession != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(
                  hasActive ? Symbols.timelapse : Symbols.fitness_center,
                  size: 20,
                  color: AppTheme.primaryContainer,
                  fill: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActive ? 'Workout in progress' : 'Ready to train?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: hasActive
                                ? AppTheme.primaryContainer
                                : AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasActive
                          ? 'Pick up where you left off, or start fresh.'
                          : 'Start empty, or jump in from a routine.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.stackMd),
          // Primary CTA dominates
          PrimaryButton(
            label: hasActive ? 'Continue workout' : 'Start empty workout',
            icon: hasActive ? Symbols.play_arrow : Symbols.add,
            onPressed: hasActive ? onContinue : onStartBlank,
          ),
          const SizedBox(height: 10),
          // Secondary actions — visually quieter
          if (hasActive)
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'New workout',
                    icon: Symbols.add,
                    onPressed: onStartBlank,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Routines',
                    icon: Symbols.bookmarks,
                    onPressed: onRoutines,
                    useAccentText: true,
                  ),
                ),
              ],
            )
          else
            SecondaryButton(
              label: 'My routines',
              icon: Symbols.bookmarks,
              onPressed: onRoutines,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick links — Hevy-style shortcut row
// ─────────────────────────────────────────────────────────────────────────────
class _QuickLinksRow extends StatelessWidget {
  final VoidCallback onRoutines;
  final VoidCallback onExercises;
  final VoidCallback onHistory;
  final VoidCallback onBuddies;

  const _QuickLinksRow({
    required this.onRoutines,
    required this.onExercises,
    required this.onHistory,
    required this.onBuddies,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: Symbols.bookmarks,
            label: 'Routines',
            onTap: onRoutines,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickLink(
            icon: Symbols.exercise,
            label: 'Exercises',
            onTap: onExercises,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickLink(
            icon: Symbols.group,
            label: 'Buddies',
            onTap: onBuddies,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickLink(
            icon: Symbols.history,
            label: 'History',
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppTheme.primaryContainer),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters
// ─────────────────────────────────────────────────────────────────────────────
class _Filter {
  final String label;
  final String? value;
  const _Filter(this.label, this.value);
}

class _FilterChipRow extends StatelessWidget {
  final List<_Filter> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterChipRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(
          filters.length,
          (i) => Padding(
            padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
            child: MetricChip(
              label: filters[i].label,
              isSelected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const _EquipmentChip({
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryContainer.withOpacity(0.12)
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: active
                ? AppTheme.primaryContainer.withOpacity(0.45)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.tune,
              size: 14,
              color: active
                  ? AppTheme.primaryContainer
                  : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              active ? '$selectedCount' : 'Gear',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: active
                        ? AppTheme.primaryContainer
                        : AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muscle-group tile
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, IconData> _bodyPartIcons = {
  'chest': Symbols.fitness_center,
  'back': Symbols.accessibility_new,
  'upper arms': Symbols.sports_martial_arts,
  'lower arms': Symbols.sports_martial_arts,
  'shoulders': Symbols.fitness_center,
  'upper legs': Symbols.directions_run,
  'lower legs': Symbols.directions_run,
  'waist': Symbols.self_improvement,
  'lower back': Symbols.accessibility_new,
  'cardio': Symbols.favorite,
  'neck': Symbols.self_improvement,
  'full body': Symbols.accessibility,
};

class _MuscleGroupTile extends StatelessWidget {
  final String bodyPart;
  final VoidCallback onTap;

  const _MuscleGroupTile({required this.bodyPart, required this.onTap});

  String get _displayName {
    if (bodyPart.isEmpty) return bodyPart;
    return bodyPart
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final icon =
        _bodyPartIcons[bodyPart.toLowerCase()] ?? Symbols.fitness_center;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppTheme.surfaceContainerHigh),
            Image.asset(
              AppMedia.bodyPart(bodyPart),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(icon, size: 32, color: AppTheme.primaryContainer),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                  Text(
                    _displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Program card
// ─────────────────────────────────────────────────────────────────────────────
class _GymProgramCard extends StatelessWidget {
  final WorkoutTemplate program;
  final VoidCallback onTap;

  const _GymProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'GYM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Symbols.verified,
                  size: 16,
                  color: AppTheme.primaryContainer,
                ),
              ],
            ),
            const Spacer(),
            Text(
              program.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${program.exercises.length} exercises',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final LocalWorkoutTemplate program;
  const _ProgramCard({required this.program});

  Color get _categoryColor {
    switch (program.category) {
      case 'hiit':
        return const Color(0xFFFF6B35);
      case 'cardio':
        return const Color(0xFF2196F3);
      case 'mobility':
        return const Color(0xFF4CAF50);
      default:
        return AppTheme.primaryContainer;
    }
  }

  String get _coverAsset {
    switch (program.category) {
      case 'cardio':
        return AppMedia.homeTrainer;
      case 'hiit':
        return AppMedia.homeHero;
      default:
        return AppMedia.homeWorkout;
    }
  }

  String get _difficultyLabel {
    final d = program.difficulty;
    if (d.isEmpty) return d;
    return '${d[0].toUpperCase()}${d.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutBuilderScreen(template: program),
        ),
      ),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: AppTheme.cardElevation,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(_coverAsset, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.surfaceContainer.withOpacity(0.92),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor.withOpacity(0.14),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: _categoryColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          _difficultyLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _categoryColor,
                                  ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        program.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${program.durationMins} min · ${program.exercises.length} exercises',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment filter sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EquipmentGridFilter extends StatefulWidget {
  final List<String> allEquipments;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;

  const _EquipmentGridFilter({
    required this.allEquipments,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_EquipmentGridFilter> createState() => _EquipmentGridFilterState();
}

class _EquipmentGridFilterState extends State<_EquipmentGridFilter> {
  late final Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter by equipment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_local.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _local.clear()),
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primaryContainer,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: widget.allEquipments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.allEquipments.length,
                    itemBuilder: (_, i) {
                      final eq = widget.allEquipments[i];
                      return CheckboxListTile(
                        value: _local.contains(eq),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _local.add(eq);
                          } else {
                            _local.remove(eq);
                          }
                        }),
                        title: Text(
                          eq,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        activeColor: AppTheme.primaryContainer,
                        checkColor: AppTheme.onPrimaryFixed,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              label: _local.isEmpty ? 'Show all' : 'Apply (${_local.length})',
              onPressed: () {
                widget.onApply(Set<String>.from(_local));
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
