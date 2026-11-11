import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/tether_text.dart';
import '../../../core/theme/tether_tokens.dart';

/// Exercise filter for PR verification dashboard
/// Allows filtering by All, Bench Press, Squat, or Deadlift
class ExerciseFilterTabs extends StatelessWidget {
  final ExerciseFilter selectedFilter;
  final ValueChanged<ExerciseFilter> onFilterChanged;
  final Map<ExerciseFilter, int>? counts;

  const ExerciseFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: TetherTokens.nightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TetherTokens.cream.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: ExerciseFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          final count = counts?[filter];
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getFilterColor(filter).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: _getFilterColor(filter).withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                ),
                margin: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFilterIcon(filter),
                          size: 16,
                          color: isSelected
                              ? _getFilterColor(filter)
                              : TetherTokens.cream.withValues(alpha: 0.5),
                        ),
                        if (count != null && count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getFilterColor(filter)
                                  : TetherTokens.cream.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: TetherText.sans(
                                10,
                                color: isSelected
                                    ? Colors.white
                                    : TetherTokens.cream.withValues(alpha: 0.6),
                                w: TetherTokens.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getFilterLabel(filter),
                      style: TetherText.sans(
                        11,
                        color: isSelected
                            ? _getFilterColor(filter)
                            : TetherTokens.cream.withValues(alpha: 0.5),
                        w: isSelected ? TetherTokens.w800 : TetherTokens.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(ExerciseFilter filter) {
    switch (filter) {
      case ExerciseFilter.all:
        return 'All';
      case ExerciseFilter.benchPress:
        return 'Bench';
      case ExerciseFilter.squat:
        return 'Squat';
      case ExerciseFilter.deadlift:
        return 'Deadlift';
    }
  }

  IconData _getFilterIcon(ExerciseFilter filter) {
    switch (filter) {
      case ExerciseFilter.all:
        return Symbols.grid_view;
      case ExerciseFilter.benchPress:
        return Symbols.fitness_center;
      case ExerciseFilter.squat:
        return Symbols.airline_seat_legroom_normal;
      case ExerciseFilter.deadlift:
        return Symbols.exercise;
    }
  }

  Color _getFilterColor(ExerciseFilter filter) {
    switch (filter) {
      case ExerciseFilter.all:
        return TetherTokens.defaultAccent;
      case ExerciseFilter.benchPress:
        return const Color(0xFF6366F1); // Indigo
      case ExerciseFilter.squat:
        return const Color(0xFFEC4899); // Pink
      case ExerciseFilter.deadlift:
        return const Color(0xFF8B5CF6); // Purple
    }
  }
}

/// Exercise filter enum for PR verification
enum ExerciseFilter {
  all,
  benchPress,
  squat,
  deadlift;

  /// Convert to API exercise name
  String? toExerciseName() {
    switch (this) {
      case ExerciseFilter.all:
        return null; // No filter
      case ExerciseFilter.benchPress:
        return 'Bench Press';
      case ExerciseFilter.squat:
        return 'Squat';
      case ExerciseFilter.deadlift:
        return 'Deadlift';
    }
  }

  /// Get display label
  String get label {
    switch (this) {
      case ExerciseFilter.all:
        return 'All Exercises';
      case ExerciseFilter.benchPress:
        return 'Bench Press';
      case ExerciseFilter.squat:
        return 'Squat';
      case ExerciseFilter.deadlift:
        return 'Deadlift';
    }
  }
}
