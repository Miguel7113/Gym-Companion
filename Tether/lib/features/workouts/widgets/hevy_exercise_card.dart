import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../models/workout_models.dart';
import 'exercise_thumbnail.dart';

/// Draft set row waiting to be logged with the checkmark action.
class DraftSetEntry {
  final String localId;
  double weightKg;
  int reps;
  double? rpe;
  bool isSaving;

  DraftSetEntry({
    required this.localId,
    this.weightKg = 0,
    this.reps = 0,
    this.rpe,
    this.isSaving = false,
  });

  factory DraftSetEntry.empty() => DraftSetEntry(
        localId: DateTime.now().microsecondsSinceEpoch.toString(),
      );
}

/// Logged set mirror used by the session screen.
class LoggedSetEntry {
  final String id;
  final int setNumber;
  final double weightKg;
  final int reps;
  final double? rpe;
  final bool isPr;

  const LoggedSetEntry({
    required this.id,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.isPr = false,
  });
}

typedef CompleteDraftCallback = Future<void> Function(
  DraftSetEntry draft,
  double weightKg,
  int reps,
  double? rpe,
);

/// Hevy-style inline exercise card for active workout logging.
class HevyExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final List<LoggedSetEntry> loggedSets;
  final List<DraftSetEntry> draftSets;
  final ProgressData? previousSet;
  final bool readOnly;
  final bool restEnabled;
  final VoidCallback onOpenInfo;
  final VoidCallback onAddDraftSet;
  final VoidCallback? onRemoveExercise;
  final VoidCallback? onToggleRest;
  final CompleteDraftCallback onCompleteDraft;
  final ValueChanged<String> onDeleteLoggedSet;

  const HevyExerciseCard({
    super.key,
    required this.exercise,
    required this.loggedSets,
    required this.draftSets,
    required this.onOpenInfo,
    required this.onAddDraftSet,
    required this.onCompleteDraft,
    required this.onDeleteLoggedSet,
    this.previousSet,
    this.readOnly = false,
    this.restEnabled = false,
    this.onRemoveExercise,
    this.onToggleRest,
  });

  @override
  State<HevyExerciseCard> createState() => _HevyExerciseCardState();
}

class _HevyExerciseCardState extends State<HevyExerciseCard> {
  final Map<String, TextEditingController> _weightCtrls = {};
  final Map<String, TextEditingController> _repsCtrls = {};

  @override
  void dispose() {
    for (final ctrl in _weightCtrls.values) {
      ctrl.dispose();
    }
    for (final ctrl in _repsCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _weightCtrl(DraftSetEntry draft) {
    return _weightCtrls.putIfAbsent(
      draft.localId,
      () => TextEditingController(
        text: draft.weightKg > 0 ? draft.weightKg.toString() : '',
      ),
    );
  }

  TextEditingController _repsCtrl(DraftSetEntry draft) {
    return _repsCtrls.putIfAbsent(
      draft.localId,
      () => TextEditingController(
        text: draft.reps > 0 ? draft.reps.toString() : '',
      ),
    );
  }

  String get _previousLabel {
    final previous = widget.previousSet;
    if (previous == null) return '—';
    return '${previous.weightKg?.toStringAsFixed(0) ?? 0}kg × ${previous.reps ?? 0}';
  }

  Future<void> _completeDraft(DraftSetEntry draft) async {
    final weight = double.tryParse(_weightCtrl(draft).text);
    final reps = int.tryParse(_repsCtrls[draft.localId]?.text ?? '');
    if (weight == null || reps == null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter weight and reps to log this set')),
      );
      return;
    }
    setState(() => draft.isSaving = true);
    await widget.onCompleteDraft(draft, weight, reps, draft.rpe);
    if (mounted) setState(() => draft.isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: thumbnail + title + menu
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 6),
            child: Row(
              children: [
                ExerciseThumbnail(exercise: ex, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onOpenInfo,
                    child: Text(
                      ex.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (!widget.readOnly && widget.onRemoveExercise != null)
                  IconButton(
                    onPressed: widget.onRemoveExercise,
                    icon: const Icon(Symbols.more_vert, size: 20),
                    color: AppTheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),

          // Notes hint (visual parity with Hevy)
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(
                'Add notes here…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant.withOpacity(0.55),
                    ),
              ),
            ),

          // Rest timer toggle
          if (!widget.readOnly && widget.onToggleRest != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: GestureDetector(
                onTap: widget.onToggleRest,
                child: Row(
                  children: [
                    Icon(
                      Symbols.timer,
                      size: 16,
                      color: widget.restEnabled
                          ? AppTheme.primaryContainer
                          : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.restEnabled
                          ? 'Rest timer: On'
                          : 'Rest timer: Off',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: widget.restEnabled
                                ? AppTheme.primaryContainer
                                : AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: const [
                _HeaderCell('Set', flex: 1),
                _HeaderCell('Previous', flex: 2),
                _HeaderCell('kg', flex: 2),
                _HeaderCell('Reps', flex: 2),
                SizedBox(width: 44),
              ],
            ),
          ),
          if (!widget.readOnly &&
              widget.draftSets.isNotEmpty &&
              widget.loggedSets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Text(
                'Tap ✓ on each set to log it',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
            ),
          const SizedBox(height: 6),

          ...widget.loggedSets.map(
            (set) => _LoggedSetRow(
              set: set,
              previousLabel: _previousLabel,
              readOnly: widget.readOnly,
              onDelete: () => widget.onDeleteLoggedSet(set.id),
            ),
          ),
          if (!widget.readOnly)
            ...widget.draftSets.map(
              (draft) => _DraftSetRow(
                draft: draft,
                setNumber: widget.loggedSets.length +
                    widget.draftSets.indexOf(draft) +
                    1,
                previousLabel: _previousLabel,
                weightCtrl: _weightCtrl(draft),
                repsCtrl: _repsCtrl(draft),
                onComplete: () => _completeDraft(draft),
              ),
            ),

          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: GestureDetector(
                onTap: widget.onAddDraftSet,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Symbols.add,
                        size: 18,
                        color: AppTheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add set',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell(this.label, {required this.flex});

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

class _SetNumberBadge extends StatelessWidget {
  final String label;
  final bool completed;

  const _SetNumberBadge({required this.label, this.completed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.primaryContainer.withOpacity(0.18)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed
              ? AppTheme.primaryContainer.withOpacity(0.35)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: completed
                  ? AppTheme.primaryContainer
                  : AppTheme.onSurface,
            ),
      ),
    );
  }
}

class _LoggedSetRow extends StatelessWidget {
  final LoggedSetEntry set;
  final String previousLabel;
  final bool readOnly;
  final VoidCallback onDelete;

  const _LoggedSetRow({
    required this.set,
    required this.previousLabel,
    required this.readOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SetNumberBadge(
                label: '${set.setNumber}',
                completed: true,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              previousLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ValueBox(value: set.weightKg.toStringAsFixed(
              set.weightKg == set.weightKg.roundToDouble() ? 0 : 1,
            )),
          ),
          Expanded(
            flex: 2,
            child: _ValueBox(value: set.reps.toString()),
          ),
          SizedBox(
            width: 44,
            child: _CheckButton(
              completed: true,
              onPressed: readOnly ? null : onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftSetRow extends StatelessWidget {
  final DraftSetEntry draft;
  final int setNumber;
  final String previousLabel;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final VoidCallback onComplete;

  const _DraftSetRow({
    required this.draft,
    required this.setNumber,
    required this.previousLabel,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SetNumberBadge(label: '$setNumber'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              previousLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _InputBox(
              controller: weightCtrl,
              hint: '—',
              onChanged: (value) {
                draft.weightKg = double.tryParse(value) ?? 0;
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: _InputBox(
              controller: repsCtrl,
              hint: '—',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                draft.reps = int.tryParse(value) ?? 0;
              },
            ),
          ),
          SizedBox(
            width: 44,
            child: _CheckButton(
              completed: false,
              isLoading: draft.isSaving,
              onPressed: draft.isSaving ? null : onComplete,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool completed;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _CheckButton({
    required this.completed,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: completed
            ? AppTheme.primaryContainer.withOpacity(0.2)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Symbols.check,
                    size: 20,
                    color: completed
                        ? AppTheme.primaryContainer
                        : AppTheme.onSurfaceVariant,
                    weight: 700,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String value;

  const _ValueBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const _InputBox({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceVariant.withOpacity(0.45),
              ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
