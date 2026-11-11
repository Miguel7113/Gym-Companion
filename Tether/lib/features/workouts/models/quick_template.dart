/// Quick workout templates for fast workout creation
/// Provides pre-built workout splits (Upper/Lower/Push/Pull/Legs/Full Body)
class QuickTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<TemplateExercise> exercises;
  final int estimatedMinutes;

  const QuickTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.exercises,
    this.estimatedMinutes = 60,
  });

  /// Predefined workout templates
  static final List<QuickTemplate> defaults = [
    QuickTemplate(
      id: 'upper',
      name: 'Upper Body',
      emoji: '💪',
      description: 'Chest, back, shoulders, arms',
      estimatedMinutes: 60,
      exercises: [
        TemplateExercise(name: 'Bench Press', sets: 4, reps: 10),
        TemplateExercise(name: 'Barbell Row', sets: 4, reps: 10),
        TemplateExercise(name: 'Overhead Press', sets: 3, reps: 10),
        TemplateExercise(name: 'Lat Pulldown', sets: 3, reps: 12),
        TemplateExercise(name: 'Dumbbell Curl', sets: 3, reps: 12),
        TemplateExercise(name: 'Tricep Pushdown', sets: 3, reps: 12),
      ],
    ),
    QuickTemplate(
      id: 'lower',
      name: 'Lower Body',
      emoji: '🦵',
      description: 'Quads, hamstrings, glutes, calves',
      estimatedMinutes: 60,
      exercises: [
        TemplateExercise(name: 'Squat', sets: 4, reps: 8),
        TemplateExercise(name: 'Romanian Deadlift', sets: 3, reps: 10),
        TemplateExercise(name: 'Leg Press', sets: 3, reps: 12),
        TemplateExercise(name: 'Leg Curl', sets: 3, reps: 12),
        TemplateExercise(name: 'Leg Extension', sets: 3, reps: 12),
        TemplateExercise(name: 'Calf Raise', sets: 3, reps: 15),
      ],
    ),
    QuickTemplate(
      id: 'push',
      name: 'Push Day',
      emoji: '🏋️',
      description: 'Chest, shoulders, triceps',
      estimatedMinutes: 55,
      exercises: [
        TemplateExercise(name: 'Bench Press', sets: 4, reps: 8),
        TemplateExercise(name: 'Incline Dumbbell Press', sets: 3, reps: 10),
        TemplateExercise(name: 'Overhead Press', sets: 3, reps: 10),
        TemplateExercise(name: 'Lateral Raise', sets: 3, reps: 12),
        TemplateExercise(name: 'Tricep Dip', sets: 3, reps: 10),
        TemplateExercise(name: 'Overhead Tricep Extension', sets: 3, reps: 12),
      ],
    ),
    QuickTemplate(
      id: 'pull',
      name: 'Pull Day',
      emoji: '🎣',
      description: 'Back, rear delts, biceps',
      estimatedMinutes: 55,
      exercises: [
        TemplateExercise(name: 'Deadlift', sets: 4, reps: 6),
        TemplateExercise(name: 'Pull Up', sets: 3, reps: 10),
        TemplateExercise(name: 'Barbell Row', sets: 3, reps: 10),
        TemplateExercise(name: 'Face Pull', sets: 3, reps: 15),
        TemplateExercise(name: 'Barbell Curl', sets: 3, reps: 10),
        TemplateExercise(name: 'Hammer Curl', sets: 3, reps: 12),
      ],
    ),
    QuickTemplate(
      id: 'legs',
      name: 'Leg Day',
      emoji: '🦿',
      description: 'Complete lower body workout',
      estimatedMinutes: 65,
      exercises: [
        TemplateExercise(name: 'Back Squat', sets: 4, reps: 8),
        TemplateExercise(name: 'Front Squat', sets: 3, reps: 10),
        TemplateExercise(name: 'Leg Extension', sets: 3, reps: 12),
        TemplateExercise(name: 'Leg Curl', sets: 3, reps: 12),
        TemplateExercise(name: 'Walking Lunge', sets: 3, reps: 12),
        TemplateExercise(name: 'Calf Raise', sets: 4, reps: 15),
      ],
    ),
    QuickTemplate(
      id: 'fullbody',
      name: 'Full Body',
      emoji: '🔥',
      description: 'Hit all major muscle groups',
      estimatedMinutes: 50,
      exercises: [
        TemplateExercise(name: 'Squat', sets: 3, reps: 10),
        TemplateExercise(name: 'Bench Press', sets: 3, reps: 10),
        TemplateExercise(name: 'Barbell Row', sets: 3, reps: 10),
        TemplateExercise(name: 'Overhead Press', sets: 3, reps: 10),
        TemplateExercise(name: 'Romanian Deadlift', sets: 3, reps: 8),
        TemplateExercise(name: 'Plank', sets: 3, durationSecs: 60),
      ],
    ),
  ];
}

/// Exercise in a template with default sets/reps
class TemplateExercise {
  final String name;
  final int sets;
  final int? reps;
  final int? durationSecs;
  final double? distanceM;

  const TemplateExercise({
    required this.name,
    required this.sets,
    this.reps,
    this.durationSecs,
    this.distanceM,
  });
}
