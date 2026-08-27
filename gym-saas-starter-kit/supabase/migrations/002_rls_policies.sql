-- ═════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═════════════════════════════════════════════════════════════════════════════

-- Helper functions

create or replace function public.get_current_gym_id()
returns uuid as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'gym_id', '')::uuid;
$$ language sql stable security definer;

create or replace function public.get_current_member_id()
returns uuid as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'member_id', '')::uuid;
$$ language sql stable security definer;

create or replace function public.get_current_user_role()
returns text as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'role', '')::text;
$$ language sql stable security definer;

-- ─────────────────────────────────────────────────────────────────────────────
-- GYMS (read-only for members, full access for staff via service role)
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.gyms enable row level security;

create policy "gyms_select_own" on public.gyms
  for select using (id = public.get_current_gym_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- GYM_MEMBERS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.gym_members enable row level security;

create policy "members_select_own_gym" on public.gym_members
  for select using (gym_id = public.get_current_gym_id());

create policy "members_update_self" on public.gym_members
  for update using (
    gym_id = public.get_current_gym_id() 
    and id = public.get_current_member_id()
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- EXERCISES
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.exercises enable row level security;

create policy "exercises_select_gym_scoped" on public.exercises
  for select using (
    gym_id is null or gym_id = public.get_current_gym_id()
  );

create policy "exercises_insert_coach" on public.exercises
  for insert with check (
    gym_id = public.get_current_gym_id()
    and public.get_current_user_role() in ('coach','admin')
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- WORKOUT TEMPLATES
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.workout_templates enable row level security;
alter table public.workout_template_exercises enable row level security;

create policy "templates_select_gym_scoped" on public.workout_templates
  for select using (
    gym_id is null or gym_id = public.get_current_gym_id()
  );

create policy "templates_insert_coach" on public.workout_templates
  for insert with check (
    gym_id = public.get_current_gym_id()
    and public.get_current_user_role() in ('coach','admin')
  );

create policy "template_exercises_select" on public.workout_template_exercises
  for select using (
    exists (
      select 1 from public.workout_templates t
      where t.id = template_id
      and (t.gym_id is null or t.gym_id = public.get_current_gym_id())
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- WORKOUT SESSIONS & SETS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.workout_sessions enable row level security;
alter table public.workout_sets enable row level security;

create policy "sessions_select_own_or_coach" on public.workout_sessions
  for select using (
    gym_id = public.get_current_gym_id()
    and (
      member_id = public.get_current_member_id()
      or public.get_current_user_role() in ('coach','admin')
    )
  );

create policy "sessions_insert_own" on public.workout_sessions
  for insert with check (
    gym_id = public.get_current_gym_id()
    and member_id = public.get_current_member_id()
  );

create policy "sets_select_via_session" on public.workout_sets
  for select using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id
      and s.gym_id = public.get_current_gym_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- PERSONAL RECORDS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.personal_records enable row level security;

create policy "prs_select_gym_scoped" on public.personal_records
  for select using (gym_id = public.get_current_gym_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- FEED POSTS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.feed_posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;

create policy "feed_select_gym_scoped" on public.feed_posts
  for select using (gym_id = public.get_current_gym_id());

create policy "feed_insert_own" on public.feed_posts
  for insert with check (
    gym_id = public.get_current_gym_id()
    and author_id = public.get_current_member_id()
  );

create policy "feed_delete_own_or_admin" on public.feed_posts
  for delete using (
    gym_id = public.get_current_gym_id()
    and (
      author_id = public.get_current_member_id()
      or public.get_current_user_role() = 'admin'
    )
  );

create policy "likes_insert_own" on public.post_likes
  for insert with check (
    exists (
      select 1 from public.feed_posts p
      where p.id = post_id and p.gym_id = public.get_current_gym_id()
    )
  );

create policy "likes_delete_own" on public.post_likes
  for delete using (member_id = public.get_current_member_id());

create policy "comments_select_gym_scoped" on public.post_comments
  for select using (
    exists (
      select 1 from public.feed_posts p
      where p.id = post_id and p.gym_id = public.get_current_gym_id()
    )
  );

create policy "comments_insert_own" on public.post_comments
  for insert with check (
    exists (
      select 1 from public.feed_posts p
      where p.id = post_id and p.gym_id = public.get_current_gym_id()
    )
    and author_id = public.get_current_member_id()
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- ACHIEVEMENTS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.achievements enable row level security;

create policy "achievements_select_gym_scoped" on public.achievements
  for select using (gym_id = public.get_current_gym_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- CLASS SCHEDULES & BOOKINGS
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.class_schedules enable row level security;
alter table public.class_bookings enable row level security;

create policy "schedules_select_gym" on public.class_schedules
  for select using (gym_id = public.get_current_gym_id());

create policy "bookings_select_own_or_coach" on public.class_bookings
  for select using (
    exists (
      select 1 from public.class_schedules s
      where s.id = schedule_id and s.gym_id = public.get_current_gym_id()
    )
    and (
      member_id = public.get_current_member_id()
      or public.get_current_user_role() in ('coach','admin')
    )
  );

create policy "bookings_insert_own" on public.class_bookings
  for insert with check (
    member_id = public.get_current_member_id()
    and exists (
      select 1 from public.class_schedules s
      where s.id = schedule_id and s.gym_id = public.get_current_gym_id()
    )
  );
