/**
 * seed-exercises.ts
 *
 * Seeds 873 exercises from the free-exercise-db dataset
 * (https://github.com/yuhonas/free-exercise-db — MIT license).
 *
 * This replaces the broken oss.exercisedb.dev pagination approach.
 * The dataset is a single flat JSON file — no pagination, no rate limits,
 * no cursor bugs. We fetch it once, map the fields, and upsert everything.
 *
 * Field mapping:
 *   free-exercise-db     → our exercises table
 *   ─────────────────────────────────────────
 *   id                   → external_id
 *   name                 → name (kept as-is — already Title Case)
 *   category             → category (strength/cardio/plyometrics/etc.)
 *   level                → difficulty (beginner/intermediate/expert)
 *   primaryMuscles       → target_muscles[]
 *   secondaryMuscles     → secondary_muscles[]
 *   equipment            → equipments[] (normalised to array)
 *   instructions         → instructions[]
 *   force/mechanic       → stored in overview as a brief descriptor
 *   images               → gif_url (first image URL, CDN-prefixed)
 *
 * body_parts is derived from primaryMuscles + category since the dataset
 * uses muscle names rather than body regions. See deriveBodyParts().
 *
 * Usage:
 *   npm run seed:exercises
 */

import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

// ─── Dataset source ───────────────────────────────────────────────────────────

const DATASET_URL =
  'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

// CDN prefix for exercise images (GitHub raw content via jsDelivr CDN)
const IMAGE_CDN =
  'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/';

// ─── Source schema types ──────────────────────────────────────────────────────

interface FreeExercise {
  id: string;
  name: string;
  force: string | null;
  level: string; // 'beginner' | 'intermediate' | 'expert'
  mechanic: string | null;
  equipment: string | null;
  primaryMuscles: string[];
  secondaryMuscles: string[];
  instructions: string[];
  category: string; // 'strength' | 'cardio' | 'plyometrics' | 'stretching' | etc.
  images: string[]; // relative paths like "3_4_Sit-Up/0.jpg"
}

// ─── Field mappings ───────────────────────────────────────────────────────────

/**
 * Maps the source category to our coarser set used by the Train screen chips.
 * Source values: strength, cardio, plyometrics, stretching, strongman,
 *                powerlifting, olympic weightlifting, crossfit
 */
function mapCategory(category: string): string {
  const c = category.toLowerCase();
  if (c === 'cardio') return 'cardio';
  if (c === 'stretching') return 'mobility';
  if (c === 'plyometrics' || c === 'crossfit') return 'hiit';
  // strength, powerlifting, strongman, olympic weightlifting → strength
  return 'strength';
}

/**
 * Derives body parts (body regions) from primaryMuscles + category.
 * free-exercise-db uses muscle names; we need region names for the
 * muscle-group browser grid.
 *
 * Mapping is intentionally broad — each muscle maps to its parent region.
 */
function deriveBodyParts(exercise: FreeExercise): string[] {
  const parts = new Set<string>();

  const muscleToRegion: Record<string, string> = {
    // Upper body push
    chest: 'chest',
    pectorals: 'chest',
    'front delts': 'shoulders',
    'side delts': 'shoulders',
    'rear delts': 'shoulders',
    shoulders: 'shoulders',
    triceps: 'upper arms',
    // Upper body pull
    lats: 'back',
    'upper back': 'back',
    traps: 'back',
    rhomboids: 'back',
    biceps: 'upper arms',
    brachialis: 'upper arms',
    forearms: 'lower arms',
    // Core
    abdominals: 'waist',
    abs: 'waist',
    obliques: 'waist',
    'lower back': 'lower back',
    // Lower body
    quadriceps: 'upper legs',
    hamstrings: 'upper legs',
    glutes: 'upper legs',
    'hip flexors': 'upper legs',
    adductors: 'upper legs',
    abductors: 'upper legs',
    calves: 'lower legs',
    // Other
    neck: 'neck',
    spine: 'back',
  };

  for (const muscle of exercise.primaryMuscles) {
    const region = muscleToRegion[muscle.toLowerCase()];
    if (region) parts.add(region);
  }

  // Fallback: if nothing matched, use category as a hint
  if (parts.size === 0) {
    if (exercise.category.toLowerCase() === 'cardio') parts.add('cardio');
    else parts.add('full body');
  }

  return [...parts];
}

/**
 * Builds a brief overview string from force + mechanic metadata.
 * These fields aren't shown directly in UI but are useful context.
 */
function buildOverview(exercise: FreeExercise): string | null {
  const parts: string[] = [];
  if (exercise.mechanic) parts.push(`${exercise.mechanic} movement`);
  if (exercise.force) parts.push(`${exercise.force} force`);
  return parts.length > 0 ? parts.join(', ') : null;
}

/**
 * Maps one free-exercise-db item to a Prisma-compatible create/update payload.
 */
function toExercisePayload(item: FreeExercise) {
  return {
    name: item.name,
    externalId: item.id,
    category: mapCategory(item.category),
    bodyParts: deriveBodyParts(item),
    targetMuscles: item.primaryMuscles,
    secondaryMuscles: item.secondaryMuscles,
    equipments: item.equipment ? [item.equipment] : [],
    difficulty: item.level === 'expert' ? 'advanced' : item.level,
    exerciseTypes: [item.category],
    // First image as the primary GIF/image URL, CDN-prefixed
    gifUrl: item.images.length > 0 ? `${IMAGE_CDN}${item.images[0]}` : null,
    // Store all image URLs as JSON for future use
    imageUrls:
      item.images.length > 0
        ? {
            small: `${IMAGE_CDN}${item.images[0]}`,
            large:
              item.images.length > 1
                ? `${IMAGE_CDN}${item.images[1]}`
                : `${IMAGE_CDN}${item.images[0]}`,
          }
        : Prisma.JsonNull,
    overview: buildOverview(item),
    instructions: item.instructions,
    isCustom: false,
    createdByUserId: null,
  };
}

// ─── Batch upsert ─────────────────────────────────────────────────────────────

const UPSERT_BATCH_SIZE = 50;

async function upsertBatch(items: FreeExercise[]): Promise<number> {
  let count = 0;
  for (const item of items) {
    const payload = toExercisePayload(item);
    await prisma.exercise.upsert({
      where: { externalId: item.id },
      create: payload,
      update: {
        name: payload.name,
        category: payload.category,
        bodyParts: payload.bodyParts,
        targetMuscles: payload.targetMuscles,
        secondaryMuscles: payload.secondaryMuscles,
        equipments: payload.equipments,
        difficulty: payload.difficulty,
        exerciseTypes: payload.exerciseTypes,
        gifUrl: payload.gifUrl,
        imageUrls:
          item.images.length > 0
            ? {
                small: `${IMAGE_CDN}${item.images[0]}`,
                large:
                  item.images.length > 1
                    ? `${IMAGE_CDN}${item.images[1]}`
                    : `${IMAGE_CDN}${item.images[0]}`,
              }
            : Prisma.JsonNull,
        overview: payload.overview,
        instructions: payload.instructions,
      },
    });
    count++;
  }
  return count;
}

// ─── Utilities ────────────────────────────────────────────────────────────────

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const startTime = Date.now();

  console.log('');
  console.log('╔══════════════════════════════════════════╗');
  console.log('║     Exercise Seed Script                  ║');
  console.log('║     Source: free-exercise-db (MIT)        ║');
  console.log('╚══════════════════════════════════════════╝');
  console.log('');

  // ── Step 1: Delete old non-custom exercises ──────────────────────────────
  console.log('▶ Step 1 — Removing old seed exercises...');
  const deleted = await prisma.exercise.deleteMany({ where: { isCustom: false } });
  console.log(`  ✓ Deleted ${deleted.count} non-custom exercises\n`);

  // ── Step 2: Fetch dataset ────────────────────────────────────────────────
  console.log('▶ Step 2 — Fetching exercise dataset...');
  console.log(`  URL: ${DATASET_URL}\n`);

  const res = await fetch(DATASET_URL);
  if (!res.ok) {
    throw new Error(`Failed to fetch dataset: ${res.status} ${res.statusText}`);
  }

  const exercises = (await res.json()) as FreeExercise[];
  console.log(`  ✓ Fetched ${exercises.length} exercises\n`);

  // ── Step 3: Upsert in batches ────────────────────────────────────────────
  console.log('▶ Step 3 — Upserting into database...');

  let seeded = 0;
  const batches = Math.ceil(exercises.length / UPSERT_BATCH_SIZE);

  for (let i = 0; i < exercises.length; i += UPSERT_BATCH_SIZE) {
    const batch = exercises.slice(i, i + UPSERT_BATCH_SIZE);
    const batchNum = Math.floor(i / UPSERT_BATCH_SIZE) + 1;
    seeded += await upsertBatch(batch);
    const pct = Math.round((seeded / exercises.length) * 100);
    process.stdout.write(
      `\r  ↳ ${seeded}/${exercises.length} (${pct}%) — batch ${batchNum}/${batches}`,
    );
  }
  console.log('');

  // ── Step 4: Verify + summary ─────────────────────────────────────────────
  console.log('\n▶ Step 4 — Verifying...');

  const totalInDb = await prisma.exercise.count({ where: { isCustom: false } });

  const byCategory = await prisma.exercise.groupBy({
    by: ['category'],
    where: { isCustom: false },
    _count: { id: true },
    orderBy: { _count: { id: 'desc' } },
  });

  const sample = await prisma.exercise.findFirst({
    where: { isCustom: false, externalId: { not: null } },
    select: {
      name: true,
      bodyParts: true,
      targetMuscles: true,
      gifUrl: true,
      category: true,
      difficulty: true,
    },
  });

  const elapsed = formatDuration(Date.now() - startTime);

  console.log('');
  console.log('╔══════════════════════════════════════════╗');
  console.log('║     Seed Complete                         ║');
  console.log('╚══════════════════════════════════════════╝');
  console.log('');
  console.log(`  Total exercises in DB : ${totalInDb}`);
  console.log(`  Time elapsed          : ${elapsed}`);
  console.log('');
  console.log('  By category:');
  for (const row of byCategory) {
    console.log(`    ${(row.category ?? 'null').padEnd(12)} ${row._count.id}`);
  }
  console.log('');
  if (sample) {
    console.log('  Sample exercise:');
    console.log(`    Name         : ${sample.name}`);
    console.log(`    Category     : ${sample.category}`);
    console.log(`    Difficulty   : ${sample.difficulty}`);
    console.log(`    Body parts   : ${sample.bodyParts.join(', ')}`);
    console.log(`    Target       : ${sample.targetMuscles.join(', ')}`);
    console.log(`    Image URL    : ${sample.gifUrl ? '✓ present' : '✗ missing'}`);
  }
  console.log('');

  if (totalInDb < exercises.length * 0.95) {
    console.warn(
      `  ⚠ Warning: fetched ${exercises.length} but only ${totalInDb} in DB. ` +
        'Some upserts may have failed.',
    );
  } else {
    console.log('  ✓ All exercises seeded successfully');
  }
  console.log('');
}

main()
  .catch((e) => {
    console.error('\n✗ Seed script failed:');
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
