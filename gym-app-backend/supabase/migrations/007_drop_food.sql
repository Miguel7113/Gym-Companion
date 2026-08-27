-- =============================================================================
-- Migration 007: Drop Food / Nutrition / Meal Plan tables
--
-- The food tracking feature has been shelved. This migration drops all
-- food-related tables, indexes, and seed data in the correct dependency order
-- (child tables before parent tables to avoid FK constraint errors).
--
-- Run in Supabase Dashboard → SQL Editor
-- This is irreversible — ensure you have a backup if you want to restore later.
-- =============================================================================

-- ── 1. Meal plan tables (depend on foods) ─────────────────────────────────────
DROP TABLE IF EXISTS "user_active_meal_plan" CASCADE;
DROP TABLE IF EXISTS "meal_plan_entries"     CASCADE;
DROP TABLE IF EXISTS "meal_plan_days"        CASCADE;
DROP TABLE IF EXISTS "meal_plans"            CASCADE;

-- ── 2. Water logs ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS "water_logs" CASCADE;

-- ── 3. Nutrition goals ────────────────────────────────────────────────────────
DROP TABLE IF EXISTS "nutrition_goals" CASCADE;

-- ── 4. Food logs (depends on foods and users) ─────────────────────────────────
DROP TABLE IF EXISTS "food_logs" CASCADE;

-- ── 5. Foods ──────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS "foods" CASCADE;

-- ── 6. Drop food-related columns added to users in migration 003/005 ──────────
ALTER TABLE "users" DROP COLUMN IF EXISTS "body_weight_kg";
ALTER TABLE "users" DROP COLUMN IF EXISTS "height_cm";
ALTER TABLE "users" DROP COLUMN IF EXISTS "age";
ALTER TABLE "users" DROP COLUMN IF EXISTS "activity_level";
ALTER TABLE "users" DROP COLUMN IF EXISTS "goal_type";

-- ── 7. Verify nothing food-related remains ────────────────────────────────────
-- Run this SELECT after the migration to confirm all dropped:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- AND table_name IN (
--   'foods','food_logs','nutrition_goals','water_logs',
--   'meal_plans','meal_plan_days','meal_plan_entries','user_active_meal_plan'
-- );
-- Expected result: 0 rows
