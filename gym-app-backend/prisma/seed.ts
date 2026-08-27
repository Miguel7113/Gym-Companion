import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const EXERCISES = [
  { name: 'Bench Press', category: 'push' },
  { name: 'Incline Bench Press', category: 'push' },
  { name: 'Overhead Press', category: 'push' },
  { name: 'Dumbbell Shoulder Press', category: 'push' },
  { name: 'Tricep Pushdown', category: 'push' },
  { name: 'Dips', category: 'push' },
  { name: 'Push-ups', category: 'push' },
  { name: 'Cable Fly', category: 'push' },
  { name: 'Deadlift', category: 'pull' },
  { name: 'Barbell Row', category: 'pull' },
  { name: 'Pull-ups', category: 'pull' },
  { name: 'Lat Pulldown', category: 'pull' },
  { name: 'Seated Cable Row', category: 'pull' },
  { name: 'Face Pull', category: 'pull' },
  { name: 'Barbell Curl', category: 'pull' },
  { name: 'Hammer Curl', category: 'pull' },
  { name: 'Squat', category: 'legs' },
  { name: 'Front Squat', category: 'legs' },
  { name: 'Leg Press', category: 'legs' },
  { name: 'Romanian Deadlift', category: 'legs' },
  { name: 'Leg Curl', category: 'legs' },
  { name: 'Leg Extension', category: 'legs' },
  { name: 'Calf Raise', category: 'legs' },
  { name: 'Lunges', category: 'legs' },
  { name: 'Bulgarian Split Squat', category: 'legs' },
  { name: 'Running', category: 'cardio' },
  { name: 'Cycling', category: 'cardio' },
  { name: 'Rowing Machine', category: 'cardio' },
  { name: 'Jump Rope', category: 'cardio' },
  { name: 'Plank', category: 'core' },
  { name: 'Crunches', category: 'core' },
  { name: 'Hanging Leg Raise', category: 'core' },
];

async function main() {
  const gym = await prisma.gym.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Pilot Gym Nairobi',
      primaryColor: '#2563EB',
      contactEmail: 'admin@pilotgym.example',
      subscriptionTier: 'trial',
      isActive: true,
    },
  });

  console.log(`Pilot gym: ${gym.name} (${gym.id})`);

  for (const entry of [
    { email: 'member1@example.com', memberName: 'Test Member 1' },
    { email: 'member2@example.com', memberName: 'Test Member 2' },
  ]) {
    await prisma.gymRoster.upsert({
      where: { gymId_email: { gymId: gym.id, email: entry.email } },
      update: {},
      create: {
        gymId: gym.id,
        email: entry.email,
        memberName: entry.memberName,
        status: 'unmatched',
      },
    });
  }

  console.log('Seeded test roster entries');

  const existingExercises = await prisma.exercise.count({ where: { isCustom: false } });
  if (existingExercises === 0) {
    await prisma.exercise.createMany({
      data: EXERCISES.map((e) => ({ ...e, isCustom: false })),
    });
    console.log(`Seeded ${EXERCISES.length} exercises`);
  } else {
    console.log(`Exercises already seeded (${existingExercises} found), skipping`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
