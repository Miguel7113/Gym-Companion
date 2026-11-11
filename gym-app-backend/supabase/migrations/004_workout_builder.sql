-- =============================================================================
-- Migration 003: Workout Builder
--
-- What this migration does:
--   1. Adds bodyWeight, height to users (for bodyweight exercise display
--      and onboarding profile)
--   2. Adds cardio fields to workout_sets (durationSecs, distanceM, speedKph)
--      so cardio and strength sets share one table
--   3. Creates workout_templates table (local default programs, DB-ready for
--      gym dashboard later)
--   4. Creates workout_template_exercises (exercises within a template,
--      ordered)
--   5. Creates saved_exercises (user bookmarks on individual exercises)
--   6. Creates saved_programs (user bookmarks on templates/programs)
--   7. Adds updated_at triggers for all new tables
--
-- Run in Supabase Dashboard → SQL Editor
-- =============================================================================


-- =============================================================================
-- PART 1 — Patch users table
-- =============================================================================

-- bodyWeight: stored in kg. Used to display bodyweight exercise context
-- and for 1RM calculations. Nullable — users set this during onboarding.
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "body_weight_kg" NUMERIC(5,2);

-- height: stored in cm. Used for BMI/fitness context on the profile screen.
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "height_cm" NUMERIC(5,1);


-- =============================================================================
-- PART 2 — Add cardio fields to workout_sets
--
-- Rather than a separate cardio_sets table, we extend workout_sets with
-- nullable cardio fields. A set is a strength set when reps/weightKg are
-- set, and a cardio set when duration/distance/speed are set.
-- The exerciseType field on Exercise (category = 'cardio') drives which
-- fields the UI shows.
-- =============================================================================

-- Duration in seconds (e.g. 1800 = 30 minutes)
ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "duration_secs" INTEGER;

-- Distance in metres (e.g. 5000 = 5km)
ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "distance_m" NUMERIC(10,2);

-- Speed in km/h (e.g. 12.5)
ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "speed_kph" NUMERIC(5,2);

-- Assisted weight in kg — for assisted pull-ups etc. where the user
-- inputs the counterweight (reduces effective bodyweight).
-- Separate from weightKg (which is the loaded weight for strength sets).
ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "assist_kg" NUMERIC(5,2);


-- =============================================================================
-- PART 3 — workout_templates
--
-- Lightweight program/template system. Initially populated with hardcoded
-- local data in Flutter, but stored in DB so gym dashboards can CRUD them
-- later without an app update.
--
-- source values:
--   'system'  — built-in defaults shipped with the app
--   'gym'     — created by a gym admin via the dashboard
--   'user'    — created by a member (future feature)
-- =============================================================================

CREATE TABLE IF NOT EXISTS "workout_templates" (
  "id"          TEXT        NOT NULL,
  -- gym_id: NULL for system templates (available to all gyms),
  -- set for gym-specific templates
  "gym_id"      TEXT,
  -- created_by_user_id: NULL for system templates
  "created_by_user_id" TEXT,
  "name"        TEXT        NOT NULL,
  "description" TEXT,
  -- category: 'strength' | 'cardio' | 'hiit' | 'mobility' | 'fullbody'
  "category"    TEXT,
  -- difficulty: 'beginner' | 'intermediate' | 'advanced'
  "difficulty"  TEXT,
  -- estimated duration in minutes
  "duration_mins" INTEGER,
  -- source: 'system' | 'gym' | 'user'
  "source"      TEXT        NOT NULL DEFAULT 'system',
  -- image_url: cover photo for the program card
  "image_url"   TEXT,
  "is_active"   BOOLEAN     NOT NULL DEFAULT true,
  "created_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "workout_templates_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "workout_templates_gym_id_idx"
  ON "workout_templates"("gym_id");

CREATE INDEX IF NOT EXISTS "workout_templates_source_idx"
  ON "workout_templates"("source");

-- FK to gyms (nullable — system templates have no gym)
ALTER TABLE "workout_templates"
  ADD CONSTRAINT "workout_templates_gym_id_fkey"
  FOREIGN KEY ("gym_id") REFERENCES "gyms"("id")
  ON DELETE CASCADE ON UPDATE CASCADE
  DEFERRABLE INITIALLY DEFERRED;

-- FK to users (nullable — system templates have no creator)
ALTER TABLE "workout_templates"
  ADD CONSTRAINT "workout_templates_created_by_user_id_fkey"
  FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;


-- =============================================================================
-- PART 4 — workout_template_exercises
--
-- The exercises within a template, with their planned sets/reps/weight.
-- sortOrder controls display order in the workout builder.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "workout_template_exercises" (
  "id"           TEXT    NOT NULL,
  "template_id"  TEXT    NOT NULL,
  "exercise_id"  TEXT    NOT NULL,
  -- sortOrder: 0-indexed position in the template exercise list
  "sort_order"   INTEGER NOT NULL DEFAULT 0,
  -- Planned defaults shown in the builder as a starting point.
  -- All nullable — user adjusts before starting.
  "default_sets"     INTEGER,
  "default_reps"     INTEGER,
  "default_weight_kg" NUMERIC(6,2),
  -- For cardio exercises
  "default_duration_secs" INTEGER,
  "default_distance_m"    NUMERIC(10,2),
  "notes"        TEXT,
  "created_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "workout_template_exercises_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "workout_template_exercises_template_id_idx"
  ON "workout_template_exercises"("template_id");

ALTER TABLE "workout_template_exercises"
  ADD CONSTRAINT "workout_template_exercises_template_id_fkey"
  FOREIGN KEY ("template_id") REFERENCES "workout_templates"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "workout_template_exercises"
  ADD CONSTRAINT "workout_template_exercises_exercise_id_fkey"
  FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;


-- =============================================================================
-- PART 5 — saved_exercises
--
-- User bookmarks on individual exercises (the explicit favourites section).
-- One row per user per exercise — unique constraint prevents duplicates.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "saved_exercises" (
  "id"          TEXT        NOT NULL,
  "user_id"     TEXT        NOT NULL,
  "exercise_id" TEXT        NOT NULL,
  "created_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "saved_exercises_pkey" PRIMARY KEY ("id")
);

-- Prevent saving the same exercise twice
CREATE UNIQUE INDEX IF NOT EXISTS "saved_exercises_user_id_exercise_id_key"
  ON "saved_exercises"("user_id", "exercise_id");

CREATE INDEX IF NOT EXISTS "saved_exercises_user_id_idx"
  ON "saved_exercises"("user_id");

ALTER TABLE "saved_exercises"
  ADD CONSTRAINT "saved_exercises_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "saved_exercises"
  ADD CONSTRAINT "saved_exercises_exercise_id_fkey"
  FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;


-- =============================================================================
-- PART 6 — saved_programs
--
-- User bookmarks on workout templates (programs they want quick access to).
-- =============================================================================

CREATE TABLE IF NOT EXISTS "saved_programs" (
  "id"          TEXT        NOT NULL,
  "user_id"     TEXT        NOT NULL,
  "template_id" TEXT        NOT NULL,
  "created_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "saved_programs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "saved_programs_user_id_template_id_key"
  ON "saved_programs"("user_id", "template_id");

CREATE INDEX IF NOT EXISTS "saved_programs_user_id_idx"
  ON "saved_programs"("user_id");

ALTER TABLE "saved_programs"
  ADD CONSTRAINT "saved_programs_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "saved_programs"
  ADD CONSTRAINT "saved_programs_template_id_fkey"
  FOREIGN KEY ("template_id") REFERENCES "workout_templates"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;


-- =============================================================================
-- PART 7 — recently_used_exercises
--
-- Auto-populated when a user logs a set for an exercise.
-- Drives the "Recently Used" row in the exercise picker.
-- upsert on (user_id, exercise_id) — updates used_at each time.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "recently_used_exercises" (
  "id"          TEXT        NOT NULL,
  "user_id"     TEXT        NOT NULL,
  "exercise_id" TEXT        NOT NULL,
  -- used_at: updated every time this exercise is logged
  "used_at"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "use_count"   INTEGER     NOT NULL DEFAULT 1,
  CONSTRAINT "recently_used_exercises_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "recently_used_exercises_user_id_exercise_id_key"
  ON "recently_used_exercises"("user_id", "exercise_id");

-- Query: ORDER BY used_at DESC LIMIT 10
CREATE INDEX IF NOT EXISTS "recently_used_exercises_user_id_used_at_idx"
  ON "recently_used_exercises"("user_id", "used_at" DESC);

ALTER TABLE "recently_used_exercises"
  ADD CONSTRAINT "recently_used_exercises_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "recently_used_exercises"
  ADD CONSTRAINT "recently_used_exercises_exercise_id_fkey"
  FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;


-- =============================================================================
-- PART 8 — updated_at triggers
-- =============================================================================

DROP TRIGGER IF EXISTS update_workout_templates_updated_at ON "workout_templates";
CREATE TRIGGER update_workout_templates_updated_at
  BEFORE UPDATE ON "workout_templates"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
