import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_media.dart';
import '../models/workout_models.dart';

/// Small circular exercise thumbnail used in Hevy-style workout cards.
class ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  final double size;

  const ExerciseThumbnail({
    super.key,
    required this.exercise,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: AppTheme.surfaceContainerHigh,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppCachedImage(
        url: exercise.gifUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(size / 2),
        fallback: Center(
          child: Icon(
            Icons.fitness_center,
            size: size * 0.42,
            color: AppTheme.onSurfaceVariant.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}
