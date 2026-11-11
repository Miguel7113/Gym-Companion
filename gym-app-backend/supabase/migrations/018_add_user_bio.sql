-- =============================================================================
-- Migration 018: Add User Bio Field
--
-- What this migration does:
--   1. Adds bio column to users table (200 character limit)
--   2. Allows users to add a personal bio to their profile
--
-- Safe to run: Uses ALTER TABLE ADD COLUMN IF NOT EXISTS
-- =============================================================================

-- Add bio column to users table
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "bio" TEXT;

-- Add check constraint for bio length (200 characters max)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'users_bio_length_check'
  ) THEN
    ALTER TABLE "users"
      ADD CONSTRAINT "users_bio_length_check" 
      CHECK (LENGTH(bio) <= 200);
  END IF;
END $$;

-- Create index for bio searches (optional, for future search functionality)
CREATE INDEX IF NOT EXISTS "users_bio_idx" ON "users" USING gin(to_tsvector('english', bio));

COMMENT ON COLUMN "users"."bio" IS 'User bio/description for profile (max 200 characters)';
