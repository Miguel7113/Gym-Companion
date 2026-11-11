-- =============================================================================
-- Migration 005: Row Level Security Policies
-- Protects direct DB access even if someone bypasses the API.
-- Your backend uses the service_role key which BYPASSES all RLS —
-- these policies only apply to anon/authenticated client-side access.
-- Run this after 001_initial_schema.sql
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_roster ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Phase 2 tables (enable after running 003_phase2_social.sql)
-- ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- Phase 3 tables (enable after running 004_phase3_ai_payments.sql)
-- ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE import_jobs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- gyms: public read (needed for gym selection screen — no auth required)
-- =============================================================================

CREATE POLICY "gyms_public_read"
    ON gyms FOR SELECT
    USING (is_active = true);

-- =============================================================================
-- users: users can only read/update their own row
-- NOTE: auth.uid() is the Supabase Auth UUID (maps to auth_provider_id in your schema)
-- =============================================================================

CREATE POLICY "users_read_own"
    ON users FOR SELECT
    USING (auth_provider_id = auth.uid()::text);

CREATE POLICY "users_update_own"
    ON users FOR UPDATE
    USING (auth_provider_id = auth.uid()::text);

-- =============================================================================
-- exercises: everyone can read (global exercise library)
-- users can insert custom exercises for themselves only
-- =============================================================================

CREATE POLICY "exercises_public_read"
    ON exercises FOR SELECT
    USING (true);

CREATE POLICY "exercises_insert_own"
    ON exercises FOR INSERT
    WITH CHECK (
        created_by_user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- workout_sessions: users can only see their own sessions
-- =============================================================================

CREATE POLICY "workout_sessions_read_own"
    ON workout_sessions FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "workout_sessions_insert_own"
    ON workout_sessions FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "workout_sessions_update_own"
    ON workout_sessions FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- workout_sets: inherit ownership through session
-- =============================================================================

CREATE POLICY "workout_sets_read_own"
    ON workout_sets FOR SELECT
    USING (
        session_id IN (
            SELECT ws.id FROM workout_sessions ws
            JOIN users u ON u.id = ws.user_id
            WHERE u.auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "workout_sets_insert_own"
    ON workout_sets FOR INSERT
    WITH CHECK (
        session_id IN (
            SELECT ws.id FROM workout_sessions ws
            JOIN users u ON u.id = ws.user_id
            WHERE u.auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- foods: public read (food catalog is shared)
-- users can insert custom foods for themselves
-- =============================================================================

CREATE POLICY "foods_public_read"
    ON foods FOR SELECT
    USING (true);

CREATE POLICY "foods_insert_own"
    ON foods FOR INSERT
    WITH CHECK (
        created_by_user_id IS NULL OR
        created_by_user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- food_logs: users can only see their own logs
-- =============================================================================

CREATE POLICY "food_logs_read_own"
    ON food_logs FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "food_logs_insert_own"
    ON food_logs FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "food_logs_update_own"
    ON food_logs FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- gym_roster: no direct client access (staff + backend only)
-- =============================================================================

CREATE POLICY "gym_roster_no_public_access"
    ON gym_roster FOR ALL
    USING (false);

-- =============================================================================
-- gym_staff: no direct client access
-- =============================================================================

CREATE POLICY "gym_staff_no_public_access"
    ON gym_staff FOR ALL
    USING (false);

-- =============================================================================
-- user_sessions: users can only see their own sessions
-- =============================================================================

CREATE POLICY "user_sessions_read_own"
    ON user_sessions FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- push_tokens: users can only manage their own tokens
-- =============================================================================

CREATE POLICY "push_tokens_read_own"
    ON push_tokens FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

CREATE POLICY "push_tokens_insert_own"
    ON push_tokens FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );

-- =============================================================================
-- user_achievements: users can read their own, gym members can read others'
-- (achievements show on the social feed)
-- =============================================================================

CREATE POLICY "user_achievements_read_own_gym"
    ON user_achievements FOR SELECT
    USING (
        gym_id IN (
            SELECT gym_id FROM users WHERE auth_provider_id = auth.uid()::text
        )
    );
