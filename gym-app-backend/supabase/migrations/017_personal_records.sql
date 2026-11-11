-- =============================================================================
-- Migration 017: Personal Records (PRs) System
--
-- What this migration does:
--   1. Creates personal_records table for user PRs
--   2. Adds coach verification workflow
--   3. Creates leaderboard views for Big 3 exercises
--   4. Adds notification support for PR verification
--   5. Adds rate limiting for PR resubmissions
--
-- Run this in the Supabase Dashboard → SQL Editor
-- =============================================================================

-- =============================================================================
-- PART 1 — Personal Records Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS personal_records (
  id TEXT PRIMARY KEY,
  gym_id TEXT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  weight_kg NUMERIC(10,2), -- NULL for bodyweight exercises
  reps INTEGER NOT NULL,
  achieved_date DATE NOT NULL,
  
  -- Verification status
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'verified', 'rejected'
  verified_by_coach_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Resubmission tracking
  submission_count INTEGER NOT NULL DEFAULT 1,
  last_submission_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- One PR per user per exercise (current best only)
  UNIQUE (gym_id, user_id, exercise_name)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS personal_records_gym_id_idx 
  ON personal_records(gym_id);

CREATE INDEX IF NOT EXISTS personal_records_user_id_idx 
  ON personal_records(user_id);

CREATE INDEX IF NOT EXISTS personal_records_status_idx 
  ON personal_records(status);

CREATE INDEX IF NOT EXISTS personal_records_exercise_name_idx 
  ON personal_records(exercise_name);

-- Index for coach pending PRs list
CREATE INDEX IF NOT EXISTS personal_records_gym_status_idx 
  ON personal_records(gym_id, status, created_at DESC);

-- Index for leaderboards (verified PRs by exercise)
CREATE INDEX IF NOT EXISTS personal_records_leaderboard_idx 
  ON personal_records(gym_id, exercise_name, status, weight_kg DESC NULLS LAST, reps DESC);

-- =============================================================================
-- PART 2 — Leaderboard Views for Big 3
-- =============================================================================

-- View for Bench Press Leaderboard
CREATE OR REPLACE VIEW bench_press_leaderboard AS
SELECT 
  pr.id,
  pr.gym_id,
  pr.user_id,
  pr.exercise_name,
  pr.weight_kg,
  pr.reps,
  pr.achieved_date,
  pr.verified_at,
  u.display_name as user_display_name,
  u.avatar_url as user_avatar_url,
  u.gender as user_gender,
  ROW_NUMBER() OVER (
    PARTITION BY pr.gym_id, u.gender 
    ORDER BY pr.weight_kg DESC NULLS LAST, pr.reps DESC
  ) as rank
FROM personal_records pr
JOIN users u ON pr.user_id = u.id
WHERE pr.exercise_name = 'Bench Press'
  AND pr.status = 'verified';

-- View for Squat Leaderboard
CREATE OR REPLACE VIEW squat_leaderboard AS
SELECT 
  pr.id,
  pr.gym_id,
  pr.user_id,
  pr.exercise_name,
  pr.weight_kg,
  pr.reps,
  pr.achieved_date,
  pr.verified_at,
  u.display_name as user_display_name,
  u.avatar_url as user_avatar_url,
  u.gender as user_gender,
  ROW_NUMBER() OVER (
    PARTITION BY pr.gym_id, u.gender 
    ORDER BY pr.weight_kg DESC NULLS LAST, pr.reps DESC
  ) as rank
FROM personal_records pr
JOIN users u ON pr.user_id = u.id
WHERE pr.exercise_name = 'Squat'
  AND pr.status = 'verified';

-- View for Deadlift Leaderboard
CREATE OR REPLACE VIEW deadlift_leaderboard AS
SELECT 
  pr.id,
  pr.gym_id,
  pr.user_id,
  pr.exercise_name,
  pr.weight_kg,
  pr.reps,
  pr.achieved_date,
  pr.verified_at,
  u.display_name as user_display_name,
  u.avatar_url as user_avatar_url,
  u.gender as user_gender,
  ROW_NUMBER() OVER (
    PARTITION BY pr.gym_id, u.gender 
    ORDER BY pr.weight_kg DESC NULLS LAST, pr.reps DESC
  ) as rank
FROM personal_records pr
JOIN users u ON pr.user_id = u.id
WHERE pr.exercise_name = 'Deadlift'
  AND pr.status = 'verified';

-- =============================================================================
-- PART 3 — Updated At Trigger
-- =============================================================================

CREATE OR REPLACE FUNCTION update_personal_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER personal_records_updated_at
  BEFORE UPDATE ON personal_records
  FOR EACH ROW
  EXECUTE FUNCTION update_personal_records_updated_at();

-- =============================================================================
-- PART 4 — RLS Policies
-- =============================================================================

-- Enable RLS
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- Users can view their own PRs (verified or not)
CREATE POLICY personal_records_view_own
  ON personal_records FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view verified PRs of others in their gym
CREATE POLICY personal_records_view_verified
  ON personal_records FOR SELECT
  USING (
    status = 'verified' 
    AND gym_id IN (
      SELECT gym_id FROM gym_members WHERE user_id = auth.uid()
    )
  );

-- Users can insert their own PRs
CREATE POLICY personal_records_insert_own
  ON personal_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own unverified PRs
CREATE POLICY personal_records_update_own
  ON personal_records FOR UPDATE
  USING (
    auth.uid() = user_id 
    AND status = 'pending'
  );

-- Users can delete their own unverified PRs
CREATE POLICY personal_records_delete_own
  ON personal_records FOR DELETE
  USING (
    auth.uid() = user_id 
    AND status = 'pending'
  );

-- Coaches can view all PRs in their gym
CREATE POLICY personal_records_coach_view
  ON personal_records FOR SELECT
  USING (
    gym_id IN (
      SELECT gym_id FROM gym_staff 
      WHERE user_id = auth.uid() 
      AND role IN ('coach', 'owner', 'admin')
    )
  );

-- Coaches can update PR status (verification)
CREATE POLICY personal_records_coach_verify
  ON personal_records FOR UPDATE
  USING (
    gym_id IN (
      SELECT gym_id FROM gym_staff 
      WHERE user_id = auth.uid() 
      AND role IN ('coach', 'owner', 'admin')
    )
  );

-- =============================================================================
-- PART 5 — Comments
-- =============================================================================

COMMENT ON TABLE personal_records IS 'User personal records (PRs) requiring coach verification. One record per user per exercise (current best only).';
COMMENT ON COLUMN personal_records.status IS 'Verification status: pending, verified, or rejected';
COMMENT ON COLUMN personal_records.weight_kg IS 'Weight in kg. NULL for bodyweight exercises like pull-ups';
COMMENT ON COLUMN personal_records.submission_count IS 'Number of times this PR has been submitted (for rate limiting)';
COMMENT ON COLUMN personal_records.last_submission_at IS 'Last time this PR was submitted (for rate limiting)';

