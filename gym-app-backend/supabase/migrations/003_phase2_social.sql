-- =============================================================================
-- Migration 003: Phase 2 — Social Layer
-- Posts, likes, comments for the gym-scoped social feed
-- Run this when starting Phase 2 social feature development
-- =============================================================================

-- =============================================================================
-- NEW TABLE: posts
-- Gym-scoped feed entries. Can be user-created or auto-generated (achievements)
-- =============================================================================

CREATE TABLE IF NOT EXISTS "posts" (
    "id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "content" TEXT,
    "image_url" TEXT,
    "achievement_type" TEXT,           -- pr / streak / milestone / null (manual post)
    "achievement_id" TEXT,             -- FK to user_achievements if auto-generated
    "is_flagged" BOOLEAN NOT NULL DEFAULT false,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "posts_gym_id_idx" ON "posts"("gym_id");
CREATE INDEX IF NOT EXISTS "posts_user_id_idx" ON "posts"("user_id");
CREATE INDEX IF NOT EXISTS "posts_created_at_idx" ON "posts"("created_at" DESC);
-- Composite for the main feed query: posts for a gym, newest first, not deleted
CREATE INDEX IF NOT EXISTS "posts_gym_id_created_at_idx"
    ON "posts"("gym_id", "created_at" DESC)
    WHERE is_deleted = false;

ALTER TABLE "posts"
    ADD CONSTRAINT "posts_gym_id_fkey"
    FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "posts"
    ADD CONSTRAINT "posts_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "posts"
    ADD CONSTRAINT "posts_achievement_id_fkey"
    FOREIGN KEY ("achievement_id") REFERENCES "user_achievements"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- NEW TABLE: post_likes
-- Simple like tracking. One like per user per post enforced by unique constraint.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "post_likes" (
    "id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "post_likes_pkey" PRIMARY KEY ("id")
);

-- Prevents duplicate likes
CREATE UNIQUE INDEX IF NOT EXISTS "post_likes_post_id_user_id_key"
    ON "post_likes"("post_id", "user_id");

CREATE INDEX IF NOT EXISTS "post_likes_post_id_idx" ON "post_likes"("post_id");
CREATE INDEX IF NOT EXISTS "post_likes_user_id_idx" ON "post_likes"("user_id");

ALTER TABLE "post_likes"
    ADD CONSTRAINT "post_likes_post_id_fkey"
    FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_likes"
    ADD CONSTRAINT "post_likes_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- =============================================================================
-- NEW TABLE: post_comments
-- Flat comments on posts (no threading in v1 — keep it simple)
-- =============================================================================

CREATE TABLE IF NOT EXISTS "post_comments" (
    "id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "post_comments_post_id_idx" ON "post_comments"("post_id");
CREATE INDEX IF NOT EXISTS "post_comments_user_id_idx" ON "post_comments"("user_id");

ALTER TABLE "post_comments"
    ADD CONSTRAINT "post_comments_post_id_fkey"
    FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_comments"
    ADD CONSTRAINT "post_comments_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TRIGGER update_post_comments_updated_at
    BEFORE UPDATE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
