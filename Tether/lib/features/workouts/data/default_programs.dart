import '../models/workout_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Default Programs — hardcoded locally in Flutter.
//
// These are shown on the Train tab and in the workout builder.
// When a user selects one, the exercise names are matched to the database
// by name in WorkoutBuilderScreen._loadTemplateExercises().
//
// Later these will also live in the DB (workout_templates table, source='system')
// so gym admins can manage them from the dashboard without app updates.
// ─────────────────────────────────────────────────────────────────────────────

final List<LocalWorkoutTemplate> defaultPrograms = [
  LocalWorkoutTemplate(
    id: 'local_push_day',
    name: 'Push Day',
    description: 'Chest, shoulders, and triceps compound + isolation work.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 50,
    imageUrl: 'https://images.unsplash.com/photo-1534368786749-b63e05c92717?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Barbell Bench Press', sets: 4, reps: 8),
      LocalTemplateExercise(exerciseName: 'Overhead Press', sets: 3, reps: 10),
      LocalTemplateExercise(exerciseName: 'Incline Dumbbell Press', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Lateral Raise', sets: 3, reps: 15),
      LocalTemplateExercise(exerciseName: 'Triceps Pushdown', sets: 3, reps: 15),
    ],
  ),
  LocalWorkoutTemplate(
    id: 'local_pull_day',
    name: 'Pull Day',
    description: 'Back and biceps — rows, pull-ups, and curls.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 50,
    imageUrl: 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Pull-Up', sets: 4, reps: 8),
      LocalTemplateExercise(exerciseName: 'Barbell Bent Over Row', sets: 4, reps: 8),
      LocalTemplateExercise(exerciseName: 'Cable Row', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Dumbbell Curl', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Face Pull', sets: 3, reps: 15),
    ],
  ),
  LocalWorkoutTemplate(
    id: 'local_leg_day',
    name: 'Leg Day',
    description: 'Quads, hamstrings, glutes, and calves.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 55,
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Barbell Squat', sets: 4, reps: 6),
      LocalTemplateExercise(exerciseName: 'Romanian Deadlift', sets: 3, reps: 10),
      LocalTemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Leg Curl', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Standing Calf Raise', sets: 4, reps: 15),
    ],
  ),
  LocalWorkoutTemplate(
    id: 'local_full_body',
    name: 'Full Body',
    description: 'Compound movements hitting every major muscle group.',
    category: 'strength',
    difficulty: 'beginner',
    durationMins: 45,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Barbell Squat', sets: 3, reps: 8),
      LocalTemplateExercise(exerciseName: 'Barbell Bench Press', sets: 3, reps: 8),
      LocalTemplateExercise(exerciseName: 'Barbell Bent Over Row', sets: 3, reps: 8),
      LocalTemplateExercise(exerciseName: 'Overhead Press', sets: 3, reps: 10),
      LocalTemplateExercise(exerciseName: 'Romanian Deadlift', sets: 3, reps: 10),
    ],
  ),
  LocalWorkoutTemplate(
    id: 'local_hiit',
    name: 'HIIT Cardio',
    description: 'High-intensity intervals to torch calories and build endurance.',
    category: 'hiit',
    difficulty: 'intermediate',
    durationMins: 30,
    imageUrl: 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Burpee', sets: 4, durationSecs: 40),
      LocalTemplateExercise(exerciseName: 'Mountain Climber', sets: 4, durationSecs: 40),
      LocalTemplateExercise(exerciseName: 'Jump Squat', sets: 4, durationSecs: 40),
      LocalTemplateExercise(exerciseName: 'Push-Up', sets: 4, reps: 15),
      LocalTemplateExercise(exerciseName: 'High Knees', sets: 4, durationSecs: 40),
    ],
  ),
  LocalWorkoutTemplate(
    id: 'local_upper_body',
    name: 'Upper Body',
    description: 'Complete upper body session — push + pull in one.',
    category: 'strength',
    difficulty: 'beginner',
    durationMins: 45,
    imageUrl: 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=70',
    exercises: const [
      LocalTemplateExercise(exerciseName: 'Dumbbell Bench Press', sets: 3, reps: 10),
      LocalTemplateExercise(exerciseName: 'Dumbbell Row', sets: 3, reps: 10),
      LocalTemplateExercise(exerciseName: 'Dumbbell Shoulder Press', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Dumbbell Curl', sets: 3, reps: 12),
      LocalTemplateExercise(exerciseName: 'Tricep Dip', sets: 3, reps: 12),
    ],
  ),
];
