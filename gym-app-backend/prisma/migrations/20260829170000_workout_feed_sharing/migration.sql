-- Link a feed post to the completed workout it represents.
ALTER TABLE "posts"
ADD COLUMN IF NOT EXISTS "workout_session_id" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "posts_workout_session_id_key"
ON "posts"("workout_session_id");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'posts_workout_session_id_fkey'
  ) THEN
    ALTER TABLE "posts"
      ADD CONSTRAINT "posts_workout_session_id_fkey"
      FOREIGN KEY ("workout_session_id") REFERENCES "workout_sessions"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END
$$;
