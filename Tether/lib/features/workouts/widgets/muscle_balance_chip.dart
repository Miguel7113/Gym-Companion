import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/workout_models.dart';

/// Shows distribution of exercises across muscle groups
class MuscleBalanceChip extends StatelessWidget {
  final List<BuilderExerciseEntry> exercises;

  const MuscleBalanceChip({
    super.key,
    required this.exercises,
  });

  Map<String, int> _calculateDistribution() {
    final counts = <String, int>{};
    for (final entry in exercises) {
      final muscles = entry.exercise.targetMuscles;
      if (muscles.isEmpty) {
        counts['Other'] = (counts['Other'] ?? 0) + 1;
      } else {
        // Count primary (first) target muscle
        final muscle = _normalizeMuscle(muscles.first);
        counts[muscle] = (counts[muscle] ?? 0) + 1;
      }
    }
    return counts;
  }

  String _normalizeMuscle(String muscle) {
    
    // Normalize common variations
    final normalized = muscle.toLowerCase();
    if (normalized.contains('chest') || normalized.contains('pec')) {
      return 'Chest';
    } else if (normalized.contains('back') || normalized.contains('lat')) {
      return 'Back';
    } else if (normalized.contains('shoulder') || normalized.contains('delt')) {
      return 'Shoulders';
    } else if (normalized.contains('bicep')) {
      return 'Biceps';
    } else if (normalized.contains('tricep')) {
      return 'Triceps';
    } else if (normalized.contains('quad') || normalized.contains('thigh')) {
      return 'Quads';
    } else if (normalized.contains('hamstring')) {
      return 'Hamstrings';
    } else if (normalized.contains('glute')) {
      return 'Glutes';
    } else if (normalized.contains('calf') || normalized.contains('calves')) {
      return 'Calves';
    } else if (normalized.contains('abs') || normalized.contains('core')) {
      return 'Core';
    }
    
    // Capitalize first letter
    return muscle[0].toUpperCase() + muscle.substring(1).toLowerCase();
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle) {
      case 'Chest':
        return const Color(0xFFFF6B6B);
      case 'Back':
        return const Color(0xFF4ECDC4);
      case 'Shoulders':
        return const Color(0xFFFFE66D);
      case 'Biceps':
        return const Color(0xFF95E1D3);
      case 'Triceps':
        return const Color(0xFFF38181);
      case 'Quads':
        return const Color(0xFF6C5CE7);
      case 'Hamstrings':
        return const Color(0xFFA29BFE);
      case 'Glutes':
        return const Color(0xFFFF7675);
      case 'Calves':
        return const Color(0xFFFD79A8);
      case 'Core':
        return const Color(0xFFFDCB6E);
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final distribution = _calculateDistribution();
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by count descending
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'MUSCLE BALANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              Text(
                '${exercises.length} exercise${exercises.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted.map((entry) {
              final color = _getMuscleColor(entry.key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
