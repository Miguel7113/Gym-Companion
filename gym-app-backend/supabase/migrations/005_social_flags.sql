-- =============================================================================
-- Migration 004: Social — post_flags table
-- Run in Supabase Dashboard → SQL Editor
-- =============================================================================

CREATE TABLE IF NOT EXISTS "post_flags" (
  "id"         TEXT        NOT NULL,
  "post_id"    TEXT        NOT NULL,
  "user_id"    TEXT        NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "post_flags_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "post_flags_post_id_user_id_key"
  ON "post_flags"("post_id", "user_id");

CREATE INDEX IF NOT EXISTS "post_flags_post_id_idx"
  ON "post_flags"("post_id");

ALTER TABLE "post_flags"
  ADD CONSTRAINT "post_flags_post_id_fkey"
  FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_flags"
  ADD CONSTRAINT "post_flags_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
