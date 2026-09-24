ALTER TABLE "posts"
ADD COLUMN IF NOT EXISTS "image_path" TEXT;

CREATE TABLE IF NOT EXISTS "coach_certifications" (
    "id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "coach_user_id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coach_certifications_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "coach_certifications_post_id_key"
ON "coach_certifications"("post_id");

CREATE INDEX IF NOT EXISTS "coach_certifications_gym_id_idx"
ON "coach_certifications"("gym_id");

CREATE INDEX IF NOT EXISTS "coach_certifications_coach_user_id_idx"
ON "coach_certifications"("coach_user_id");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'coach_certifications_post_id_fkey'
  ) THEN
    ALTER TABLE "coach_certifications"
      ADD CONSTRAINT "coach_certifications_post_id_fkey"
      FOREIGN KEY ("post_id") REFERENCES "posts"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'coach_certifications_coach_user_id_fkey'
  ) THEN
    ALTER TABLE "coach_certifications"
      ADD CONSTRAINT "coach_certifications_coach_user_id_fkey"
      FOREIGN KEY ("coach_user_id") REFERENCES "users"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'coach_certifications_gym_id_fkey'
  ) THEN
    ALTER TABLE "coach_certifications"
      ADD CONSTRAINT "coach_certifications_gym_id_fkey"
      FOREIGN KEY ("gym_id") REFERENCES "gyms"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END
$$;
