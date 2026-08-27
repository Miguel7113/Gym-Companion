-- AlterTable
ALTER TABLE "users" ADD COLUMN     "body_weight_kg" DECIMAL(5,2),
ADD COLUMN     "height_cm" DECIMAL(5,1);

-- AlterTable
ALTER TABLE "workout_sets" ADD COLUMN     "assist_kg" DECIMAL(5,2),
ADD COLUMN     "distance_m" DECIMAL(10,2),
ADD COLUMN     "duration_secs" INTEGER,
ADD COLUMN     "speed_kph" DECIMAL(5,2);

-- CreateTable
CREATE TABLE "workout_templates" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT,
    "created_by_user_id" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT,
    "difficulty" TEXT,
    "duration_mins" INTEGER,
    "source" TEXT NOT NULL DEFAULT 'system',
    "image_url" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_template_exercises" (
    "id" TEXT NOT NULL,
    "template_id" TEXT NOT NULL,
    "exercise_id" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "default_sets" INTEGER,
    "default_reps" INTEGER,
    "default_weight_kg" DECIMAL(6,2),
    "default_duration_secs" INTEGER,
    "default_distance_m" DECIMAL(10,2),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_template_exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_exercises" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "exercise_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_programs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "template_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_programs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recently_used_exercises" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "exercise_id" TEXT NOT NULL,
    "used_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "use_count" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "recently_used_exercises_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "workout_templates_gym_id_idx" ON "workout_templates"("gym_id");

-- CreateIndex
CREATE INDEX "workout_templates_source_idx" ON "workout_templates"("source");

-- CreateIndex
CREATE INDEX "workout_template_exercises_template_id_idx" ON "workout_template_exercises"("template_id");

-- CreateIndex
CREATE INDEX "saved_exercises_user_id_idx" ON "saved_exercises"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "saved_exercises_user_id_exercise_id_key" ON "saved_exercises"("user_id", "exercise_id");

-- CreateIndex
CREATE INDEX "saved_programs_user_id_idx" ON "saved_programs"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "saved_programs_user_id_template_id_key" ON "saved_programs"("user_id", "template_id");

-- CreateIndex
CREATE INDEX "recently_used_exercises_user_id_used_at_idx" ON "recently_used_exercises"("user_id", "used_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "recently_used_exercises_user_id_exercise_id_key" ON "recently_used_exercises"("user_id", "exercise_id");

-- AddForeignKey
ALTER TABLE "workout_templates" ADD CONSTRAINT "workout_templates_gym_id_fkey" FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_templates" ADD CONSTRAINT "workout_templates_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_template_exercises" ADD CONSTRAINT "workout_template_exercises_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "workout_templates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_template_exercises" ADD CONSTRAINT "workout_template_exercises_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_exercises" ADD CONSTRAINT "saved_exercises_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_exercises" ADD CONSTRAINT "saved_exercises_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_programs" ADD CONSTRAINT "saved_programs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_programs" ADD CONSTRAINT "saved_programs_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "workout_templates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recently_used_exercises" ADD CONSTRAINT "recently_used_exercises_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recently_used_exercises" ADD CONSTRAINT "recently_used_exercises_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;
