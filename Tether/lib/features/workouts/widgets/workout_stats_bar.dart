import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/media_catalog.dart';
import '../models/workout_models.dart';

/// Compact duration / volume / sets row shown under the workout session header.
class WorkoutStatsBar extends StatelessWidget {
  final Duration elapsed;
  final double totalVolumeKg;
  final int totalSets;
  final Iterable<Exercise> exercises;

  const WorkoutStatsBar({
    super.key,
    required this.elapsed,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.exercises,
  });

  /// Hevy-style elapsed: `15s`, `12min 3s`, `1h 5min`
  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return m > 0 ? '${h}h ${m}min' : '${h}h';
    }
    if (m > 0) {
      return s > 0 ? '${m}min ${s}s' : '${m}min';
    }
    return '${s}s';
  }

  Set<String> get _bodyParts {
    final parts = <String>{};
    for (final ex in exercises) {
      if (ex.bodyParts.isNotEmpty) {
        parts.add(ex.bodyParts.first.toLowerCase());
      }
    }
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final parts = _bodyParts.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
      child: Row(
        children: [
          _StatChip(
            label: 'Duration',
            value: _formatElapsed(elapsed),
            highlight: true,
          ),
          const SizedBox(width: 20),
          _StatChip(
            label: 'Volume',
            value: '${totalVolumeKg.toStringAsFixed(0)} kg',
          ),
          const SizedBox(width: 20),
          _StatChip(label: 'Sets', value: '$totalSets'),
          const Spacer(),
          if (parts.isNotEmpty)
            Row(
              children: parts
                  .map(
                    (part) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          AppMedia.bodyPart(part),
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Icon(
              Symbols.accessibility_new,
              size: 22,
              color: AppTheme.onSurfaceVariant.withOpacity(0.4),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: highlight
                    ? AppTheme.primaryContainer
                    : AppTheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}
