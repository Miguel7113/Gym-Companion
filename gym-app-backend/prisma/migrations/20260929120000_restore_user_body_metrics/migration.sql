-- 20260730161200_workout_builder is recorded as applied, but these columns are
-- missing from the live database. Re-add them idempotently.
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "body_weight_kg" DECIMAL(5,2);
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "height_cm" DECIMAL(5,1);
