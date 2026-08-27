import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseDetailScreen
//
// Shows full exercise info: GIF, muscles, equipment, instructions.
// Two entry points:
//   1. onAddToWorkout != null  → shows "ADD TO WORKOUT" button (builder mode)
//   2. onAddToWorkout == null  → read-only (browse mode)
// ─────────────────────────────────────────────────────────────────────────────
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final VoidCallback? onAddToWorkout;
  final bool isSaved;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.onAddToWorkout,
    this.isSaved = false,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  late bool _saved;
  bool _savingToggle = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
  }

  Future<void> _toggleSave() async {
    setState(() => _savingToggle = true);
    try {
      final svc = ref.read(workoutServiceProvider);
      if (_saved) {
        await svc.unsaveExercise(widget.exercise.id);
      } else {
        await svc.saveExercise(widget.exercise.id);
      }
      setState(() => _saved = !_saved);
    } catch (e) {
      debugPrint('[ExerciseDetail] toggleSave failed: $e');
    } finally {
      if (mounted) setState(() => _savingToggle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── GIF / Hero header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Symbols.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _savingToggle ? null : _toggleSave,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: _savingToggle
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(
                              _saved ? Symbols.bookmark : Symbols.bookmark,
                              fill: _saved ? 1 : 0,
                              color: _saved
                                  ? AppTheme.primaryContainer
                                  : Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ex.gifUrl != null
                      ? Image.network(
                          ex.gifUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _GifPlaceholder(ex: ex),
                        )
                      : _GifPlaceholder(ex: ex),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.containerMargin,
                  AppTheme.stackMd,
                  AppTheme.containerMargin,
                  widget.onAddToWorkout != null ? 120 : 32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Name + difficulty badge ────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ex.name,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (ex.difficulty != null) ...[
                          const SizedBox(width: 12),
                          _DifficultyBadge(difficulty: ex.difficulty!),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppTheme.stackSm),

                    // ── Category + exercise type chips ─────────────────
                    if (ex.category != null || ex.bodyParts.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (ex.category != null)
                            _InfoChip(
                              label: ex.category!.toUpperCase(),
                              icon: Symbols.fitness_center,
                              highlight: true,
                            ),
                          ...ex.bodyParts.map((b) => _InfoChip(label: b.toUpperCase())),
                        ],
                      ),

                    const SizedBox(height: AppTheme.stackMd),

                    // ── Equipment ──────────────────────────────────────
                    if (ex.equipments.isNotEmpty) ...[
                      _SectionHeader(label: 'EQUIPMENT'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ex.equipments.map((e) =>
                          _InfoChip(
                            label: e.toUpperCase(),
                            icon: Symbols.sports_gymnastics,
                          ),
                        ).toList(),
                      ),
                      const SizedBox(height: AppTheme.stackMd),
                    ],

                    // ── Primary muscles ────────────────────────────────
                    if (ex.targetMuscles.isNotEmpty) ...[
                      _SectionHeader(label: 'PRIMARY MUSCLES'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ex.targetMuscles.map((m) =>
                          _InfoChip(
                            label: m.toUpperCase(),
                            icon: Symbols.fiber_manual_record,
                            highlight: true,
                          ),
                        ).toList(),
                      ),
                      const SizedBox(height: AppTheme.stackMd),
                    ],

                    // ── Secondary muscles ──────────────────────────────
                    if (ex.secondaryMuscles.isNotEmpty) ...[
                      _SectionHeader(label: 'SECONDARY MUSCLES'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ex.secondaryMuscles.map((m) =>
                          _InfoChip(label: m.toUpperCase()),
                        ).toList(),
                      ),
                      const SizedBox(height: AppTheme.stackMd),
                    ],

                    // ── Overview ───────────────────────────────────────
                    if (ex.overview != null && ex.overview!.isNotEmpty) ...[
                      _SectionHeader(label: 'OVERVIEW'),
                      const SizedBox(height: 8),
                      Text(
                        ex.overview!,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.6),
                      ),
                      const SizedBox(height: AppTheme.stackMd),
                    ],

                    // ── Instructions ───────────────────────────────────
                    if (ex.instructions.isNotEmpty) ...[
                      _SectionHeader(label: 'HOW TO DO IT'),
                      const SizedBox(height: 12),
                      ...ex.instructions.asMap().entries.map((e) =>
                        _InstructionStep(
                          number: e.key + 1,
                          text: e.value
                              .replaceFirst(RegExp(r'^Step:\d+\s*'), ''),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky ADD TO WORKOUT button ───────────────────────────────
          if (widget.onAddToWorkout != null)
            Positioned(
              left: AppTheme.containerMargin,
              right: AppTheme.containerMargin,
              bottom: bottomPad + 16,
              child: PrimaryButton(
                label: 'Add to Workout',
                icon: Symbols.add,
                onPressed: () {
                  widget.onAddToWorkout!();
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _GifPlaceholder extends StatelessWidget {
  final Exercise ex;
  const _GifPlaceholder({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.fitness_center, size: 48,
                color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(ex.name,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return const Color(0xFF4CAF50);
      case 'intermediate': return const Color(0xFFFF9800);
      case 'advanced': return const Color(0xFFF44336);
      default: return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _color),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppTheme.onSurfaceVariant),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool highlight;
  const _InfoChip({required this.label, this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryContainer.withOpacity(0.1)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: highlight
              ? AppTheme.primaryContainer.withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;
  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppTheme.primaryContainer),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
