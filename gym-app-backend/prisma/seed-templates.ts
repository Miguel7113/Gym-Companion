/**
 * seed-templates.ts
 *
 * Seeds 6 system workout templates into the workout_templates table,
 * with exercises linked by name from the already-seeded exercises table.
 *
 * Run with: npm run seed:templates
 *
 * Safe to re-run — uses upsert on template name so it won't duplicate.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ─────────────────────────────────────────────────────────────────────────────
// Template definitions
// Each exercise is matched by name against the exercises table.
// If an exercise isn't found it's skipped — the template still creates.
// ─────────────────────────────────────────────────────────────────────────────
interface TemplateExerciseDef {
  name: string;
  sets: number;
  reps?: number;
  durationSecs?: number;
  notes?: string;
}

interface TemplateDef {
  name: string;
  description: string;
  category: string;
  difficulty: string;
  durationMins: number;
  exercises: TemplateExerciseDef[];
}

const TEMPLATES: TemplateDef[] = [
  {
    name: 'Push Day',
    description: 'Chest, shoulders, and triceps. Classic horizontal and vertical push patterns.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 55,
    exercises: [
      { name: 'Barbell Bench Press', sets: 4, reps: 8 },
      { name: 'Incline Dumbbell Press', sets: 3, reps: 10 },
      { name: 'Overhead Press', sets: 3, reps: 8 },
      { name: 'Lateral Raise', sets: 3, reps: 15, notes: 'Light weight, controlled' },
      { name: 'Triceps Pushdown', sets: 3, reps: 12 },
    ],
  },
  {
    name: 'Pull Day',
    description: 'Back and biceps. Vertical and horizontal pulling for a balanced upper body.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 55,
    exercises: [
      { name: 'Deadlift', sets: 4, reps: 5, notes: 'Focus on hip hinge' },
      { name: 'Barbell Row', sets: 4, reps: 8 },
      { name: 'Pull Up', sets: 3, reps: 8 },
      { name: 'Face Pull', sets: 3, reps: 15, notes: 'External rotation at top' },
      { name: 'Barbell Curl', sets: 3, reps: 10 },
    ],
  },
  {
    name: 'Leg Day',
    description: 'Quads, hamstrings, and calves. Full lower body compound and isolation work.',
    category: 'strength',
    difficulty: 'intermediate',
    durationMins: 60,
    exercises: [
      { name: 'Barbell Squat', sets: 4, reps: 8 },
      { name: 'Romanian Deadlift', sets: 3, reps: 10 },
      { name: 'Leg Press', sets: 3, reps: 12 },
      { name: 'Leg Curl', sets: 3, reps: 12 },
      { name: 'Standing Calf Raise', sets: 4, reps: 15 },
    ],
  },
  {
    name: 'Full Body',
    description: 'One session hits everything. Ideal for 2–3 days per week training.',
    category: 'strength',
    difficulty: 'beginner',
    durationMins: 50,
    exercises: [
      { name: 'Barbell Squat', sets: 3, reps: 8 },
      { name: 'Barbell Bench Press', sets: 3, reps: 8 },
      { name: 'Barbell Row', sets: 3, reps: 8 },
      { name: 'Overhead Press', sets: 3, reps: 8 },
      { name: 'Romanian Deadlift', sets: 3, reps: 10 },
    ],
  },
  {
    name: 'Cardio Burn',
    description: 'Mixed cardio circuit. Rotate machines to keep heart rate up.',
    category: 'cardio',
    difficulty: 'beginner',
    durationMins: 40,
    exercises: [
      { name: 'Treadmill Running', sets: 1, durationSecs: 1200, notes: '20 min at moderate pace' },
      { name: 'Stationary Bike', sets: 1, durationSecs: 900, notes: '15 min intervals' },
      { name: 'Jump Rope', sets: 3, durationSecs: 180 },
    ],
  },
  {
    name: 'Core & Mobility',
    description: 'Core stability and flexibility. Great as a finisher or standalone session.',
    category: 'mobility',
    difficulty: 'beginner',
    durationMins: 30,
    exercises: [
      { name: 'Plank', sets: 3, durationSecs: 60 },
      { name: 'Hanging Leg Raise', sets: 3, reps: 12 },
      { name: 'Crunch', sets: 3, reps: 20 },
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Seed runner
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║     Workout Templates Seed Script         ║');
  console.log('╚══════════════════════════════════════════╝\n');

  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const def of TEMPLATES) {
    console.log(`  Processing: ${def.name}...`);

    // Check if template already exists
    const existing = await prisma.workoutTemplate.findFirst({
      where: { name: def.name, source: 'system' },
    });

    if (existing) {
      // Delete and recreate so exercises are in sync
      await prisma.workoutTemplateExercise.deleteMany({
        where: { templateId: existing.id },
      });
      await prisma.workoutTemplate.delete({ where: { id: existing.id } });
    }

    // Create the template
    const template = await prisma.workoutTemplate.create({
      data: {
        name: def.name,
        description: def.description,
        category: def.category,
        difficulty: def.difficulty,
        durationMins: def.durationMins,
        source: 'system',
        isActive: true,
      },
    });

    // Match and link exercises
    let exercisesLinked = 0;
    let exercisesSkipped = 0;

    for (let i = 0; i < def.exercises.length; i++) {
      const ex = def.exercises[i];

      // Search by exact name first, then partial match
      let exercise = await prisma.exercise.findFirst({
        where: { name: { equals: ex.name, mode: 'insensitive' } },
      });

      if (!exercise) {
        // Try partial match — handles "Barbell Bench Press" → "Bench Press"
        exercise = await prisma.exercise.findFirst({
          where: {
            name: { contains: ex.name.split(' ').pop()!, mode: 'insensitive' },
            isCustom: false,
          },
        });
      }

      if (!exercise) {
        console.log(`    ⚠ Exercise not found: "${ex.name}" — skipping`);
        exercisesSkipped++;
        continue;
      }

      await prisma.workoutTemplateExercise.create({
        data: {
          templateId: template.id,
          exerciseId: exercise.id,
          sortOrder: i,
          defaultSets: ex.sets,
          defaultReps: ex.reps ?? null,
          defaultDurationSecs: ex.durationSecs ?? null,
          notes: ex.notes ?? null,
        },
      });
      exercisesLinked++;
    }

    console.log(
      `    ✓ Created with ${exercisesLinked}/${def.exercises.length} exercises` +
      (exercisesSkipped > 0 ? ` (${exercisesSkipped} not found)` : ''),
    );

    if (existing) updated++;
    else created++;
  }

  console.log(`\n  ✓ Done: ${created} created, ${updated} updated, ${skipped} skipped\n`);
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
