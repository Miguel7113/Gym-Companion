-- Used for server-authoritative local-calendar streaks.
ALTER TABLE "gyms"
ADD COLUMN IF NOT EXISTS "timezone" TEXT NOT NULL DEFAULT 'UTC';
