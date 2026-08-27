-- =============================================================================
-- Migration 008: Row Level Security Policies
--
-- What this migration does:
--   1. Creates JWT helper functions that read gym_id/member_id/role
--      from the Supabase JWT claims (injected by auth-verify-otp)
--   2. Enables RLS on every user-facing table
--   3. Creates policies so members only see their gym's data
--
-- Run AFTER migrations 001-007 in the Supabase SQL Editor.
--
-- How it works:
--   The auth-verify-otp Edge Function writes gym_id, member_id, role
--   into auth.users.raw_user_meta_data. Supabase embeds these in the JWT
--   as user_metadata. Our helper functions read them and all policies
--   use the helpers — so every query is automatically scoped to the
--   member's gym without any application-level WHERE clauses.
-- =============================================================================

-- =============================================================================
-- PART 1 — JWT helper functions
-- =============================================================================

-- Reads gym_id from the JWT. Returns NULL for unauthenticated requests.
create or replace function public.get_my_gym_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'gym_id'),
    ''
  )::uuid;
$$;

-- Reads member_id (our users.id) from the JWT.
create or replace function public.get_my_member_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'member_id'),
    ''
  )::uuid;
$$;

-- Reads role from the JWT (member | coach | admin).
create or replace function public.get_my_role()
returns text
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'role'),
    ''
  )::text;
$$;

-- Convenience: true if the current user is coach or admin in their gym.
create or replace function public.is_staff()
returns boolean
language sql stable security definer
as $$
  select coalesce(
    (auth.jwt() -> 'user_metadata' ->> 'role') in ('coach', 'admin'),
    false
  );
$$;


-- =============================================================================
-- PART 2 — Enable RLS and add policies
-- =============================================================================

-- ── gyms ──────────────────────────────────────────────────────────────────────
alter table public.gyms enable row level security;

-- Anyone (authenticated or not) can read active gyms.
-- This is required so the gym selection screen works before login.
create policy "gyms: public read active"
  on public.gyms for select
  using (is_active = true);


-- ── users ─────────────────────────────────────────────────────────────────────
alter table public.users enable row level security;

-- Members can read any user in their gym (for social features, coach lookup)
create policy "users: read within gym"
  on public.users for select
  using (gym_id = public.get_my_gym_id());

-- Members can update only their own profile
create policy "users: update own profile"
  on public.users for update
  using (id = public.get_my_member_id());


-- ── gym_roster ────────────────────────────────────────────────────────────────
alter table public.gym_roster enable row level security;

-- Coaches/admins can read the full roster; members can only see their own entry
create policy "gym_roster: staff read all"
  on public.gym_roster for select
  using (
    gym_id = public.get_my_gym_id()
    and (
      public.is_staff()
      or matched_user_id = public.get_my_member_id()
    )
  );

-- Only the Edge Function (service role) writes to gym_roster — no member policy needed


-- ── gym_staff ─────────────────────────────────────────────────────────────────
alter table public.gym_staff enable row level security;

-- Members can see staff names (for the feed STAFF badge, coach profiles)
create policy "gym_staff: read within gym"
  on public.gym_staff for select
  using (gym_id = public.get_my_gym_id());


-- ── exercises ─────────────────────────────────────────────────────────────────
alter table public.exercises enable row level security;

-- Global exercises (no gym_id) are visible to everyone
-- Gym-specific exercises are visible only to that gym
create policy "exercises: read global or own gym"
  on public.exercises for select
  using (
    is_custom = false
    or gym_id is null
    or gym_id = public.get_my_gym_id()
  );

-- Any authenticated member can create a custom exercise for their gym
create policy "exercises: member can create custom"
  on public.exercises for insert
  with check (
    gym_id = public.get_my_gym_id()
    and created_by_user_id = public.get_my_member_id()
  );


-- ── workout_sessions ──────────────────────────────────────────────────────────
alter table public.workout_sessions enable row level security;

-- Members see only their own sessions; coaches see all sessions in the gym
create policy "workout_sessions: read own or coach"
  on public.workout_sessions for select
  using (
    gym_id = public.get_my_gym_id()
    and (
      user_id = public.get_my_member_id()
      or public.is_staff()
    )
  );

create policy "workout_sessions: member insert own"
  on public.workout_sessions for insert
  with check (
    gym_id = public.get_my_gym_id()
    and user_id = public.get_my_member_id()
  );

create policy "workout_sessions: member update own"
  on public.workout_sessions for update
  using (
    gym_id = public.get_my_gym_id()
    and user_id = public.get_my_member_id()
  );


-- ── workout_sets ──────────────────────────────────────────────────────────────
alter table public.workout_sets enable row level security;

-- Access via session — if you can see the session you can see its sets
create policy "workout_sets: access via session"
  on public.workout_sets for select
  using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id
      and s.gym_id = public.get_my_gym_id()
      and (
        s.user_id = public.get_my_member_id()
        or public.is_staff()
      )
    )
  );

create policy "workout_sets: insert via own session"
  on public.workout_sets for insert
  with check (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id
      and s.user_id = public.get_my_member_id()
    )
  );

create policy "workout_sets: update own"
  on public.workout_sets for update
  using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id
      and s.user_id = public.get_my_member_id()
    )
  );


-- ── user_achievements ─────────────────────────────────────────────────────────
alter table public.user_achievements enable row level security;

create policy "user_achievements: read own gym"
  on public.user_achievements for select
  using (gym_id = public.get_my_gym_id());


-- ── posts ─────────────────────────────────────────────────────────────────────
alter table public.posts enable row level security;

-- All members of a gym can see all posts in that gym's feed
create policy "posts: read own gym"
  on public.posts for select
  using (
    gym_id = public.get_my_gym_id()
    and is_deleted = false
  );

-- Members can post if they are the author (type restricted at app layer)
create policy "posts: member insert"
  on public.posts for insert
  with check (
    gym_id = public.get_my_gym_id()
    and user_id = public.get_my_member_id()
  );

-- Authors can soft-delete their own posts; staff can delete any
create policy "posts: delete own or staff"
  on public.posts for update
  using (
    gym_id = public.get_my_gym_id()
    and (
      user_id = public.get_my_member_id()
      or public.is_staff()
    )
  );


-- ── post_likes ────────────────────────────────────────────────────────────────
alter table public.post_likes enable row level security;

create policy "post_likes: read own gym"
  on public.post_likes for select
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_id and p.gym_id = public.get_my_gym_id()
    )
  );

create policy "post_likes: insert own"
  on public.post_likes for insert
  with check (
    user_id = public.get_my_member_id()
    and exists (
      select 1 from public.posts p
      where p.id = post_id and p.gym_id = public.get_my_gym_id()
    )
  );

create policy "post_likes: delete own"
  on public.post_likes for delete
  using (user_id = public.get_my_member_id());


-- ── post_comments ─────────────────────────────────────────────────────────────
alter table public.post_comments enable row level security;

create policy "post_comments: read own gym"
  on public.post_comments for select
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_id and p.gym_id = public.get_my_gym_id()
    )
  );

create policy "post_comments: insert own"
  on public.post_comments for insert
  with check (
    user_id = public.get_my_member_id()
    and exists (
      select 1 from public.posts p
      where p.id = post_id and p.gym_id = public.get_my_gym_id()
    )
  );

create policy "post_comments: delete own"
  on public.post_comments for delete
  using (user_id = public.get_my_member_id());


-- ── post_flags ────────────────────────────────────────────────────────────────
alter table public.post_flags enable row level security;

create policy "post_flags: insert own"
  on public.post_flags for insert
  with check (user_id = public.get_my_member_id());

create policy "post_flags: read own"
  on public.post_flags for select
  using (user_id = public.get_my_member_id());


-- ── user_sessions (auth refresh tokens) ──────────────────────────────────────
alter table public.user_sessions enable row level security;

create policy "user_sessions: own only"
  on public.user_sessions for all
  using (user_id = public.get_my_member_id());


-- ── push_tokens ───────────────────────────────────────────────────────────────
alter table public.push_tokens enable row level security;

create policy "push_tokens: own only"
  on public.push_tokens for all
  using (user_id = public.get_my_member_id());


-- ── saved_exercises ───────────────────────────────────────────────────────────
alter table public.saved_exercises enable row level security;

create policy "saved_exercises: own only"
  on public.saved_exercises for all
  using (user_id = public.get_my_member_id());


-- ── saved_programs ────────────────────────────────────────────────────────────
alter table public.saved_programs enable row level security;

create policy "saved_programs: own only"
  on public.saved_programs for all
  using (user_id = public.get_my_member_id());


-- ── recently_used_exercises ───────────────────────────────────────────────────
alter table public.recently_used_exercises enable row level security;

create policy "recently_used_exercises: own only"
  on public.recently_used_exercises for all
  using (user_id = public.get_my_member_id());


-- ── workout_templates ─────────────────────────────────────────────────────────
alter table public.workout_templates enable row level security;

-- System templates (gym_id = null) visible to all
-- Gym templates visible to members of that gym
-- User templates visible to the owner
create policy "workout_templates: read accessible"
  on public.workout_templates for select
  using (
    is_active = true
    and (
      (source = 'system' and gym_id is null)
      or gym_id = public.get_my_gym_id()
      or user_id = public.get_my_member_id()
    )
  );

create policy "workout_templates: user can create own"
  on public.workout_templates for insert
  with check (
    user_id = public.get_my_member_id()
    and source = 'user'
  );

create policy "workout_templates: user can update own"
  on public.workout_templates for update
  using (
    user_id = public.get_my_member_id()
    and source = 'user'
  );


-- =============================================================================
-- PART 3 — Service role bypass (already built into Postgres)
-- The service role key bypasses all RLS policies automatically.
-- NestJS backend uses the service role key so all backend-side operations
-- (session creation, PR detection, social auto-posting) are not blocked by RLS.
-- =============================================================================
