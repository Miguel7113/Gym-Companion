-- CreateTable
CREATE TABLE "gyms" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "logo_url" TEXT,
    "primary_color" TEXT,
    "contact_email" TEXT,
    "subscription_tier" TEXT NOT NULL DEFAULT 'trial',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "gyms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gym_staff" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'admin',
    "auth_provider_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gym_staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gym_roster" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "member_name" TEXT,
    "external_member_id" TEXT,
    "status" TEXT NOT NULL DEFAULT 'unmatched',
    "matched_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gym_roster_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "roster_id" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "display_name" TEXT,
    "subscription_tier" TEXT NOT NULL DEFAULT 'free',
    "auth_provider_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercises" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT,
    "is_custom" BOOLEAN NOT NULL DEFAULT false,
    "created_by_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_sessions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL,
    "ended_at" TIMESTAMP(3),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_sets" (
    "id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "exercise_id" TEXT NOT NULL,
    "set_number" INTEGER,
    "reps" INTEGER,
    "weight_kg" DECIMAL(10,2),
    "rpe" DECIMAL(3,1),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_sets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "foods" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "source" TEXT,
    "external_id" TEXT,
    "calories_per_100g" DECIMAL(10,2),
    "protein_g" DECIMAL(10,2),
    "carbs_g" DECIMAL(10,2),
    "fat_g" DECIMAL(10,2),
    "is_local_custom" BOOLEAN NOT NULL DEFAULT false,
    "created_by_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "foods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "food_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "food_id" TEXT NOT NULL,
    "logged_at" TIMESTAMP(3) NOT NULL,
    "quantity_g" DECIMAL(10,2),
    "meal_type" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "food_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "gym_staff_email_key" ON "gym_staff"("email");

-- CreateIndex
CREATE INDEX "gym_roster_gym_id_idx" ON "gym_roster"("gym_id");

-- CreateIndex
CREATE UNIQUE INDEX "gym_roster_gym_id_email_key" ON "gym_roster"("gym_id", "email");

-- CreateIndex
CREATE UNIQUE INDEX "gym_roster_gym_id_phone_key" ON "gym_roster"("gym_id", "phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_auth_provider_id_key" ON "users"("auth_provider_id");

-- CreateIndex
CREATE INDEX "workout_sessions_user_id_idx" ON "workout_sessions"("user_id");

-- CreateIndex
CREATE INDEX "workout_sets_session_id_idx" ON "workout_sets"("session_id");

-- CreateIndex
CREATE INDEX "foods_external_id_idx" ON "foods"("external_id");

-- CreateIndex
CREATE INDEX "food_logs_user_id_logged_at_idx" ON "food_logs"("user_id", "logged_at");

-- AddForeignKey
ALTER TABLE "gym_staff" ADD CONSTRAINT "gym_staff_gym_id_fkey" FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gym_roster" ADD CONSTRAINT "gym_roster_gym_id_fkey" FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_gym_id_fkey" FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercises" ADD CONSTRAINT "exercises_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_gym_id_fkey" FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sets" ADD CONSTRAINT "workout_sets_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sets" ADD CONSTRAINT "workout_sets_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "foods" ADD CONSTRAINT "foods_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "food_logs" ADD CONSTRAINT "food_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "food_logs" ADD CONSTRAINT "food_logs_food_id_fkey" FOREIGN KEY ("food_id") REFERENCES "foods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
