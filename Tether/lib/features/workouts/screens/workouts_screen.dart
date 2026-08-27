import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/offline_workout_service.dart';
import '../data/default_programs.dart';
import 'workout_builder_screen.dart';
import 'workout_history_screen.dart';
import 'exercise_picker_sheet.dart';
import 'progress_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutsScreen — Train tab
//
// Sections:
//   1. TRAIN app bar (glass, progress tap → ProgressScreen)
//   2. Start Workout CTA (lime pill)
//   3. BROWSE EXERCISES section label
//   4. Category filter chips (ALL / STRENGTH / CARDIO / HIIT / MOBILITY)
//   5. Muscle-group browser grid (loaded from GET /exercises/body-parts)
//   6. RECENT WORKOUTS section label
//   7. WorkoutHistoryScreen inline
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
    _Filter('ALL', null),
    _Filter('STRENGTH', 'strength'),
    _Filter('CARDIO', 'cardio'),
    _Filter('HIIT', 'hiit'),
    _Filter('MOBILITY', 'mobility'),
  ];

  List<String> _bodyParts = [];
  bool _loadingBodyParts = true;
  bool _bodyPartsError = false;

  @override
  void initState() {
    super.initState();
    _loadBodyParts();
  }

  Future<void> _loadBodyParts() async {
    setState(() { _loadingBodyParts = true; _bodyPartsError = false; });
    try {
      final svc = ref.read(offlineWorkoutServiceProvider);
      final parts = await svc.listBodyParts();
      if (mounted) setState(() { _bodyParts = parts; _loadingBodyParts = false; });
    } catch (e) {
      debugPrint('[WorkoutsScreen] _loadBodyParts failed: $e');
      if (mounted) setState(() { _loadingBodyParts = false; _bodyPartsError = true; });
    }
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
          _selectedEquipment..clear()..addAll(sel);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _TrainAppBar(
        onProgressTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBodyParts,
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surfaceContainerHigh,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 80)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.containerMargin),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.stackMd),

                  // ── 1. Start Workout CTA ───────────────────────────────
                  PrimaryButton(
                    label: 'Start Workout',
                    icon: Symbols.play_arrow,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkoutBuilderScreen()),
                    ),
                  ),

                  const SizedBox(height: AppTheme.stackMd),

                  // ── Programs ───────────────────────────────────────────
                  Text('PROGRAMS',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: AppTheme.stackSm),
                  _ProgramsRow(),
                  const SizedBox(height: AppTheme.stackLg),

                  // ── 2. Browse Exercises header ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BROWSE EXERCISES',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      Row(
                        children: [
                          // Equipment filter button
                          GestureDetector(
                            onTap: _showEquipmentFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _selectedEquipment.isNotEmpty
                                    ? AppTheme.primaryContainer.withOpacity(0.12)
                                    : AppTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull),
                                border: Border.all(
                                  color: _selectedEquipment.isNotEmpty
                                      ? AppTheme.primaryContainer.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Symbols.tune, size: 12,
                                    color: _selectedEquipment.isNotEmpty
                                        ? AppTheme.primaryContainer
                                        : AppTheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedEquipment.isEmpty
                                        ? 'EQUIPMENT'
                                        : '${_selectedEquipment.length} SELECTED',
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                      color: _selectedEquipment.isNotEmpty
                                          ? AppTheme.primaryContainer
                                          : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openExerciseList(),
                            child: Text('SEE ALL',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.primaryContainer)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.stackSm),

                  // ── 3. Category filter chips ───────────────────────────
                  _FilterChipRow(
                    filters: _filters,
                    selectedIndex: _selectedFilter,
                    onSelected: (i) =>
                        setState(() => _selectedFilter = i),
                  ),

                  const SizedBox(height: AppTheme.stackSm),
                ]),
              ),
            ),

            // ── 4. Muscle-group browser grid ───────────────────────────────
            if (_loadingBodyParts)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.containerMargin),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => SkeletonBox(
                      width: double.infinity,
                      height: double.infinity,
                      radius: AppTheme.radiusXxl,
                    ),
                    childCount: 8,
                  ),
                ),
              )
            else if (_bodyPartsError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.containerMargin),
                  child: ConnectErrorState(onRetry: _loadBodyParts),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.containerMargin),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _MuscleGroupTile(
                      bodyPart: _bodyParts[i],
                      onTap: () =>
                          _openExerciseList(bodyPart: _bodyParts[i]),
                    ),
                    childCount: _bodyParts.length,
                  ),
                ),
              ),

            // ── 5. Recent Workouts ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.containerMargin),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.stackLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT WORKOUTS',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.stackSm),
                  const SizedBox(
                    height: 440,
                    child: WorkoutHistoryScreen(),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter data
// ─────────────────────────────────────────────────────────────────────────────
class _Filter {
  final String label;
  final String? value; // null = ALL
  const _Filter(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _TrainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProgressTap;
  const _TrainAppBar({required this.onProgressTap});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64 + topPadding,
          padding: EdgeInsets.only(
            top: topPadding,
            left: AppTheme.gutter,
            right: AppTheme.gutter,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'TRAIN',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                  letterSpacing: 0.05 * 28,
                  shadows: [
                    Shadow(
                      color: AppTheme.primaryContainer.withOpacity(0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onProgressTap,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceContainerHigh,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: const Icon(Symbols.bar_chart,
                      size: 18, color: AppTheme.onSurface),
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
// Filter chip row
// ─────────────────────────────────────────────────────────────────────────────
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
            padding:
                EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
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

// ─────────────────────────────────────────────────────────────────────────────
// Muscle-group browser tile
//
// Each body part maps to a photo from Unsplash and an icon.
// Tapping opens ExerciseListScreen filtered to that body part.
// ─────────────────────────────────────────────────────────────────────────────

// Photo + icon mapping for each body part
const Map<String, _BodyPartMeta> _bodyPartMeta = {
  'chest': _BodyPartMeta(
    icon: Symbols.fitness_center,
    imageUrl: 'https://images.unsplash.com/photo-1534368786749-b63e05c92717?w=400&q=70',
  ),
  'back': _BodyPartMeta(
    icon: Symbols.accessibility_new,
    imageUrl: 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=400&q=70',
  ),
  'upper arms': _BodyPartMeta(
    icon: Symbols.sports_martial_arts,
    imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&q=70',
  ),
  'lower arms': _BodyPartMeta(
    icon: Symbols.sports_martial_arts,
    imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=70',
  ),
  'shoulders': _BodyPartMeta(
    icon: Symbols.fitness_center,
    imageUrl: 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=400&q=70',
  ),
  'upper legs': _BodyPartMeta(
    icon: Symbols.directions_run,
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=70',
  ),
  'lower legs': _BodyPartMeta(
    icon: Symbols.directions_run,
    imageUrl: 'https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=400&q=70',
  ),
  'waist': _BodyPartMeta(
    icon: Symbols.self_improvement,
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&q=70',
  ),
  'lower back': _BodyPartMeta(
    icon: Symbols.accessibility_new,
    imageUrl: 'https://images.unsplash.com/photo-1566241832378-917a0f30db2c?w=400&q=70',
  ),
  'cardio': _BodyPartMeta(
    icon: Symbols.favorite,
    imageUrl: 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&q=70',
  ),
  'neck': _BodyPartMeta(
    icon: Symbols.self_improvement,
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=70',
  ),
  'full body': _BodyPartMeta(
    icon: Symbols.accessibility,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&q=70',
  ),
};

// Fallback for unknown body parts
const _BodyPartMeta _fallbackMeta = _BodyPartMeta(
  icon: Symbols.fitness_center,
  imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=70',
);

class _BodyPartMeta {
  final IconData icon;
  final String imageUrl;
  const _BodyPartMeta({required this.icon, required this.imageUrl});
}

class _MuscleGroupTile extends StatelessWidget {
  final String bodyPart;
  final VoidCallback onTap;

  const _MuscleGroupTile({required this.bodyPart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _bodyPartMeta[bodyPart.toLowerCase()] ?? _fallbackMeta;
    final displayName = bodyPart.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          image: DecorationImage(
            image: NetworkImage(meta.imageUrl),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.78),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon pill
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: Icon(meta.icon, size: 16, color: Colors.white),
              ),
              // Body part name
              Text(
                displayName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 8)
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Programs horizontal scroll row
// ─────────────────────────────────────────────────────────────────────────────
class _ProgramsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: defaultPrograms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _ProgramCard(program: defaultPrograms[i]),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final LocalWorkoutTemplate program;
  const _ProgramCard({required this.program});

  Color get _categoryColor {
    switch (program.category) {
      case 'hiit': return const Color(0xFFFF6B35);
      case 'cardio': return const Color(0xFF2196F3);
      case 'mobility': return const Color(0xFF4CAF50);
      default: return AppTheme.primaryContainer;
    }
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
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          image: DecorationImage(
            image: NetworkImage(program.imageUrl),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.82),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: _categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  program.difficulty.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _categoryColor,
                    fontSize: 9,
                  ),
                ),
              ),
              // Name + duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(
                        color: Colors.black.withOpacity(0.6), blurRadius: 8)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${program.durationMins} MIN · '
                    '${program.exercises.length} EXERCISES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      shadows: [Shadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment filter bottom sheet (reused from Train tab)
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
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
                Expanded(child: Text('FILTER BY EQUIPMENT',
                  style: Theme.of(context).textTheme.labelLarge)),
                if (_local.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _local.clear()),
                    child: Text('CLEAR',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTheme.primaryContainer)),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45),
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
                          if (v == true) _local.add(eq);
                          else _local.remove(eq);
                        }),
                        title: Text(eq,
                          style: Theme.of(context).textTheme.bodyMedium),
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
              label: _local.isEmpty
                  ? 'Show All'
                  : 'Apply (${_local.length})',
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
