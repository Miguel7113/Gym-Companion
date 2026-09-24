-- Link completed workout sessions to the routine used to start them.
ALTER TABLE "workout_sessions"
ADD COLUMN IF NOT EXISTS "template_id" TEXT;

CREATE INDEX IF NOT EXISTS "workout_sessions_template_id_idx"
ON "workout_sessions"("template_id");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'workout_sessions_template_id_fkey'
  ) THEN
    ALTER TABLE "workout_sessions"
    ADD CONSTRAINT "workout_sessions_template_id_fkey"
    FOREIGN KEY ("template_id") REFERENCES "workout_templates"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
