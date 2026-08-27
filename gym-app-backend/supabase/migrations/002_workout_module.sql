-- =============================================================================
-- Migration 002: Workout Module Expansion
--
-- What this migration does:
--   1. Adds missing updated_at columns to gym_staff, workout_sessions,
--      workout_sets (they exist in the Prisma schema but were absent from
--      the first Supabase migration)
--   2. Adds soft-delete (deleted_at) to workout_sessions and workout_sets
--   3. Expands the exercises table with all ExerciseDB fields
--   4. Adds gender column to users
--   5. Creates Phase 2 tables: user_sessions, push_tokens, user_achievements,
--      posts, post_likes, post_comments
--   6. Wires up updated_at triggers for all new/updated tables
--   7. Adds all necessary indexes and foreign keys
--
-- Run this in the Supabase Dashboard → SQL Editor
-- Safe to run on a fresh DB (all statements use IF NOT EXISTS / IF column
-- doesn't exist guards where possible).
-- =============================================================================


-- =============================================================================
-- PART 1 — Patch existing tables
-- Add columns that were in the Prisma schema but missing from migration 001
-- =============================================================================

-- gym_staff: add updated_at (was missing from 001)
ALTER TABLE "gym_staff"
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- workout_sessions: add updated_at + soft-delete
ALTER TABLE "workout_sessions"
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE "workout_sessions"
  ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ;

-- workout_sets: add updated_at + soft-delete
ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE "workout_sets"
  ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ;

-- food_logs: add updated_at + soft-delete (referenced in phase2-plan as missing)
-- NOTE: foods and food_logs were intentionally excluded from migration 001.
-- They are created fresh here as full tables.

CREATE TABLE IF NOT EXISTS "foods" (
  "id"                TEXT        NOT NULL,
  "name"              TEXT        NOT NULL,
  "source"            TEXT,
  "external_id"       TEXT,
  "calories_per_100g" NUMERIC(10,2),
  "protein_g"         NUMERIC(10,2),
  "carbs_g"           NUMERIC(10,2),
  "fat_g"             NUMERIC(10,2),
  "is_local_custom"   BOOLEAN     NOT NULL DEFAULT false,
  "created_by_user_id" TEXT,
  "created_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "foods_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "foods_external_id_idx" ON "foods"("external_id");

ALTER TABLE "foods"
  ADD CONSTRAINT "foods_created_by_user_id_fkey"
  FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS "food_logs" (
  "id"          TEXT        NOT NULL,
  "user_id"     TEXT        NOT NULL,
  "food_id"     TEXT        NOT NULL,
  "logged_at"   TIMESTAMPTZ NOT NULL,
  "quantity_g"  NUMERIC(10,2),
  "meal_type"   TEXT,
  "deleted_at"  TIMESTAMPTZ,
  "created_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "food_logs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "food_logs_user_id_logged_at_idx"
  ON "food_logs"("user_id", "logged_at");

ALTER TABLE "food_logs"
  ADD CONSTRAINT "food_logs_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "food_logs"
  ADD CONSTRAINT "food_logs_food_id_fkey"
  FOREIGN KEY ("food_id") REFERENCES "foods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- users: add gender column for plan defaults
-- Values: 'male' | 'female' | 'other' | NULL
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "gender" TEXT;


-- =============================================================================
-- PART 2 — Expand the exercises table for ExerciseDB
--
-- The existing table has: id, name, category, is_custom, created_by_user_id,
-- created_at. We're adding all ExerciseDB fields.
--
-- All new columns are nullable so existing rows (the 32 seeded exercises)
-- don't break. The seed-exercises.ts script will DELETE all non-custom rows
-- and re-insert from ExerciseDB, so nulls won't live long.
-- =============================================================================

-- ExerciseDB's own ID — used as the upsert key in the seed script
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "external_id" TEXT;

-- body_parts: text array e.g. {chest,"upper arms"}
-- PostgreSQL text[] is the native array type — maps to String[] in Prisma
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "body_parts" TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "target_muscles" TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "secondary_muscles" TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "equipments" TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "difficulty" TEXT;

ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "exercise_types" TEXT[] NOT NULL DEFAULT '{}';

-- gif_url: URL to ExerciseDB CDN GIF
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "gif_url" TEXT;

-- image_urls: JSONB object { small, medium, large }
-- JSONB not JSON — binary storage, faster queries, supports indexing
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "image_urls" JSONB;

-- overview: 1-2 sentence description
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "overview" TEXT;

-- instructions: ordered steps e.g. {"Step:1 Lie face down...","Step:2 ..."}
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "instructions" TEXT[] NOT NULL DEFAULT '{}';

-- updated_at: was missing from 001
ALTER TABLE "exercises"
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Unique constraint on external_id so upserts are safe
-- (DO NOTHING on conflict with this key in the seed script)
CREATE UNIQUE INDEX IF NOT EXISTS "exercises_external_id_key"
  ON "exercises"("external_id");

-- Index for muscle-group browser: WHERE 'chest' = ANY(body_parts)
-- GIN (Generalized Inverted Index) is the correct index type for array contains
CREATE INDEX IF NOT EXISTS "exercises_body_parts_gin_idx"
  ON "exercises" USING GIN("body_parts");

CREATE INDEX IF NOT EXISTS "exercises_target_muscles_gin_idx"
  ON "exercises" USING GIN("target_muscles");

CREATE INDEX IF NOT EXISTS "exercises_equipments_gin_idx"
  ON "exercises" USING GIN("equipments");


-- =============================================================================
-- PART 3 — Phase 2 new tables
-- =============================================================================

-- ---------------------------------------------------------------------------
-- user_sessions — refresh token store for persistent auth across app restarts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "user_sessions" (
  "id"            TEXT        NOT NULL,
  "user_id"       TEXT        NOT NULL,
  -- refresh_token: the Supabase refresh token stored securely on device.
  -- UNIQUE enforces one active token per device (the app updates this on each
  -- token refresh cycle — old value out, new value in).
  "refresh_token" TEXT        NOT NULL,
  "device_info"   TEXT,
  -- platform: 'ios' | 'android' | 'web'
  "platform"      TEXT,
  "created_at"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "last_used_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "expires_at"    TIMESTAMPTZ,
  CONSTRAINT "user_sessions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "user_sessions_refresh_token_key"
  ON "user_sessions"("refresh_token");

CREATE INDEX IF NOT EXISTS "user_sessions_user_id_idx"
  ON "user_sessions"("user_id");

ALTER TABLE "user_sessions"
  ADD CONSTRAINT "user_sessions_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- push_tokens — FCM device tokens for push notifications
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "push_tokens" (
  "id"           TEXT        NOT NULL,
  "user_id"      TEXT        NOT NULL,
  -- device_token: the FCM registration token. UNIQUE because one physical
  -- device should only appear once in this table.
  "device_token" TEXT        NOT NULL,
  -- platform: 'ios' | 'android'
  "platform"     TEXT        NOT NULL,
  "created_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "push_tokens_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "push_tokens_device_token_key"
  ON "push_tokens"("device_token");

CREATE INDEX IF NOT EXISTS "push_tokens_user_id_idx"
  ON "push_tokens"("user_id");

ALTER TABLE "push_tokens"
  ADD CONSTRAINT "push_tokens_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- user_achievements — milestones and PRs, used for social auto-posts
--
-- achievement_type values:
--   'pr'        — personal record on a specific exercise (exerciseId set)
--   'streak'    — workout streak milestone (e.g. 7-day streak)
--   'milestone' — generic milestone (e.g. "100th workout")
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "user_achievements" (
  "id"               TEXT        NOT NULL,
  "user_id"          TEXT        NOT NULL,
  "gym_id"           TEXT        NOT NULL,
  "achievement_type" TEXT        NOT NULL,
  -- value: human-readable description e.g. "100kg bench press", "7-day streak"
  "value"            TEXT,
  -- exercise_id: set for 'pr' type, null for 'streak'/'milestone'
  "exercise_id"      TEXT,
  "earned_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "created_at"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "user_achievements_user_id_idx"
  ON "user_achievements"("user_id");

CREATE INDEX IF NOT EXISTS "user_achievements_gym_id_idx"
  ON "user_achievements"("gym_id");

ALTER TABLE "user_achievements"
  ADD CONSTRAINT "user_achievements_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_achievements"
  ADD CONSTRAINT "user_achievements_gym_id_fkey"
  FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "user_achievements"
  ADD CONSTRAINT "user_achievements_exercise_id_fkey"
  FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- posts — gym-scoped social feed entries
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "posts" (
  "id"               TEXT        NOT NULL,
  "gym_id"           TEXT        NOT NULL,
  "user_id"          TEXT        NOT NULL,
  "content"          TEXT,
  "image_url"        TEXT,
  -- achievement_type: if this post was auto-generated from an achievement,
  -- this mirrors the achievement_type value for feed filtering
  "achievement_type" TEXT,
  "achievement_id"   TEXT,
  "is_flagged"       BOOLEAN     NOT NULL DEFAULT false,
  "is_deleted"       BOOLEAN     NOT NULL DEFAULT false,
  "created_at"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "posts_gym_id_idx"  ON "posts"("gym_id");
CREATE INDEX IF NOT EXISTS "posts_user_id_idx" ON "posts"("user_id");
-- Feed query: WHERE gym_id = $1 AND is_deleted = false ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS "posts_gym_id_created_at_idx"
  ON "posts"("gym_id", "created_at" DESC);

ALTER TABLE "posts"
  ADD CONSTRAINT "posts_gym_id_fkey"
  FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "posts"
  ADD CONSTRAINT "posts_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "posts"
  ADD CONSTRAINT "posts_achievement_id_fkey"
  FOREIGN KEY ("achievement_id") REFERENCES "user_achievements"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- post_likes — simple like tracking, one row per user per post
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "post_likes" (
  "id"         TEXT        NOT NULL,
  "post_id"    TEXT        NOT NULL,
  "user_id"    TEXT        NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "post_likes_pkey" PRIMARY KEY ("id")
);

-- Prevent a user liking the same post twice
CREATE UNIQUE INDEX IF NOT EXISTS "post_likes_post_id_user_id_key"
  ON "post_likes"("post_id", "user_id");

CREATE INDEX IF NOT EXISTS "post_likes_post_id_idx" ON "post_likes"("post_id");

ALTER TABLE "post_likes"
  ADD CONSTRAINT "post_likes_post_id_fkey"
  FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_likes"
  ADD CONSTRAINT "post_likes_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- post_comments — threaded comments on posts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "post_comments" (
  "id"         TEXT        NOT NULL,
  "post_id"    TEXT        NOT NULL,
  "user_id"    TEXT        NOT NULL,
  "content"    TEXT        NOT NULL,
  "is_deleted" BOOLEAN     NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "post_comments_post_id_idx" ON "post_comments"("post_id");

ALTER TABLE "post_comments"
  ADD CONSTRAINT "post_comments_post_id_fkey"
  FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_comments"
  ADD CONSTRAINT "post_comments_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- =============================================================================
-- PART 4 — updated_at triggers for all new/patched tables
--
-- The trigger function update_updated_at_column() was created in migration 001.
-- We drop-then-recreate each trigger so this script is safe to re-run and
-- doesn't conflict with any triggers already attached in migration 001.
-- =============================================================================

-- gym_staff trigger was already created in 001 — drop first to avoid duplicate error
DROP TRIGGER IF EXISTS update_gym_staff_updated_at ON "gym_staff";
CREATE TRIGGER update_gym_staff_updated_at
  BEFORE UPDATE ON "gym_staff"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_exercises_updated_at ON "exercises";
CREATE TRIGGER update_exercises_updated_at
  BEFORE UPDATE ON "exercises"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_sessions_updated_at ON "workout_sessions";
CREATE TRIGGER update_workout_sessions_updated_at
  BEFORE UPDATE ON "workout_sessions"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_sets_updated_at ON "workout_sets";
CREATE TRIGGER update_workout_sets_updated_at
  BEFORE UPDATE ON "workout_sets"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_foods_updated_at ON "foods";
CREATE TRIGGER update_foods_updated_at
  BEFORE UPDATE ON "foods"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_food_logs_updated_at ON "food_logs";
CREATE TRIGGER update_food_logs_updated_at
  BEFORE UPDATE ON "food_logs"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_push_tokens_updated_at ON "push_tokens";
CREATE TRIGGER update_push_tokens_updated_at
  BEFORE UPDATE ON "push_tokens"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_posts_updated_at ON "posts";
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON "posts"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_post_comments_updated_at ON "post_comments";
CREATE TRIGGER update_post_comments_updated_at
  BEFORE UPDATE ON "post_comments"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
