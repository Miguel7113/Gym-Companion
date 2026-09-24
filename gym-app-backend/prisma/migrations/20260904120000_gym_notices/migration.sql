-- Gym notices: Home + Notices screens (not social feed)
CREATE TABLE IF NOT EXISTS "gym_notices" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "author_user_id" TEXT,
    "author_staff_id" TEXT,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "tag" TEXT NOT NULL,
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "published_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "deleted_at" TIMESTAMPTZ,
    CONSTRAINT "gym_notices_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "gym_notices_gym_id_idx" ON "gym_notices"("gym_id");
CREATE INDEX IF NOT EXISTS "gym_notices_gym_id_deleted_at_is_pinned_published_at_idx"
    ON "gym_notices"("gym_id", "deleted_at", "is_pinned", "published_at");

ALTER TABLE "gym_notices"
    ADD CONSTRAINT "gym_notices_gym_id_fkey"
    FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "gym_notices"
    ADD CONSTRAINT "gym_notices_author_user_id_fkey"
    FOREIGN KEY ("author_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "gym_notices"
    ADD CONSTRAINT "gym_notices_author_staff_id_fkey"
    FOREIGN KEY ("author_staff_id") REFERENCES "gym_staff"("id") ON DELETE SET NULL ON UPDATE CASCADE;
