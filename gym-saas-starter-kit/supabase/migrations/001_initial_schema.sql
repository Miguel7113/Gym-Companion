-- ═════════════════════════════════════════════════════════════════════════════
-- GYM SAAS PLATFORM — INITIAL SCHEMA
-- No nutrition tables. Focus: workouts, feed, achievements, coaching.
-- ═════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CORE TENANT TABLES
-- ─────────────────────────────────────────────────────────────────────────────

create table public.gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  code text unique not null,                    -- e.g. "IRONPUMP2024"
  logo_url text,
  primary_color text default '#FF6B35',
  subscription_status text check (subscription_status in ('active','past_due','cancelled','trialing')) default 'trialing',
  subscription_expires_at timestamptz,
  plan_tier text default 'standard',
  max_members int default 200,
  admin_email text not null,
  billing_email text,
  stripe_customer_id text,
  stripe_subscription_id text,
  settings jsonb default '{
    "features": {
      "workout_tracking": true,
      "social_feed": true,
      "coach_messaging": true,
      "pr_leaderboard": true,
      "class_booking": false
    }
  }'::jsonb,
  created_at timestamptz default now()
);

comment on table public.gyms is 'Gym tenants. Each gym pays a flat monthly fee.';
comment on column public.gyms.code is 'Short code members enter to find their gym in the app.';

-- Pre-registered members (admin uploads these before members can log in)
create table public.gym_members (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  email text,
  phone text,                                   -- E.164 format: +1234567890
  full_name text,
  avatar_url text,
  date_of_birth date,
  gender text,
  fitness_goal text,
  experience_level text default 'beginner',
  auth_user_id uuid references auth.users(id) on delete set null,
  role text check (role in ('member','coach','admin')) default 'member',
  is_active boolean default true,
  claimed_at timestamptz,
  last_active_at timestamptz,
  metadata jsonb default '{}'::jsonb,
  constraint contact_info_required check (email is not null or phone is not null),
  unique(gym_id, email),
  unique(gym_id, phone)
);

create index idx_gym_members_lookup on public.gym_members(gym_id, email, phone);
create index idx_gym_members_auth on public.gym_members(auth_user_id);

-- Gym staff for admin portal (separate auth flow: email + password)
create table public.gym_staff (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  auth_user_id uuid references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  role text check (role in ('owner','manager','coach')) default 'coach',
  is_active boolean default true,
  created_at timestamptz default now()
);

-- OTP rate limiting log
create table public.otp_logs (
  id uuid primary key default gen_random_uuid(),
  contact text not null,
  gym_id uuid references public.gyms(id),
  member_id uuid references public.gym_members(id),
  created_at timestamptz default now()
);

create index idx_otp_logs_contact on public.otp_logs(contact, created_at);

-- Push notification tokens
create table public.push_tokens (
  member_id uuid references public.gym_members(id) on delete cascade,
  token text not null,
  platform text check (platform in ('ios','android')) not null,
  updated_at timestamptz default now(),
  primary key (member_id, platform)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. WORKOUT TABLES
-- ─────────────────────────────────────────────────────────────────────────────

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade,
  name text not null,
  category text,
  body_parts text[] default '{}',
  target_muscles text[] default '{}',
  secondary_muscles text[] default '{}',
  equipments text[] default '{}',
  difficulty text check (difficulty in ('beginner','intermediate','advanced')),
  gif_url text,
  instructions text[] default '{}',
  overview text,
  is_custom boolean default false,
  created_by_user_id uuid references public.gym_members(id),
  created_at timestamptz default now()
);

create index idx_exercises_gym on public.exercises(gym_id, name);

create table public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade,
  created_by uuid references public.gym_members(id),
  name text not null,
  description text,
  category text,
  difficulty text,
  duration_mins int,
  source text check (source in ('system','gym','user')) default 'user',
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table public.workout_template_exercises (
  id uuid primary key default gen_random_uuid(),
  template_id uuid references public.workout_templates(id) on delete cascade not null,
  exercise_id uuid references public.exercises(id) not null,
  sort_order int default 0,
  default_sets int,
  default_reps int,
  default_weight_kg decimal(8,2),
  default_duration_secs int,
  default_distance_m decimal(10,2),
  notes text
);

create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  member_id uuid references public.gym_members(id) on delete cascade not null,
  template_id uuid references public.workout_templates(id),
  started_at timestamptz default now(),
  ended_at timestamptz,
  notes text,
  pr_achieved boolean default false,
  created_at timestamptz default now()
);

create index idx_sessions_member on public.workout_sessions(member_id, started_at desc);

create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.workout_sessions(id) on delete cascade not null,
  exercise_id uuid references public.exercises(id) not null,
  set_number int,
  reps int,
  weight_kg decimal(8,2),
  rpe decimal(3,1),
  assist_kg decimal(8,2),
  duration_secs int,
  distance_m decimal(10,2),
  speed_kph decimal(5,2),
  created_at timestamptz default now()
);

create index idx_sets_session on public.workout_sets(session_id, exercise_id);

-- Personal Records
create table public.personal_records (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  member_id uuid references public.gym_members(id) on delete cascade not null,
  exercise_id uuid references public.exercises(id) not null,
  record_type text check (record_type in ('weight','reps','distance','duration')) not null,
  value decimal(10,2) not null,
  unit text not null,
  session_id uuid references public.workout_sessions(id),
  achieved_at timestamptz default now(),
  unique(member_id, exercise_id, record_type)
);

create index idx_prs_member on public.personal_records(member_id, achieved_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. SOCIAL FEED TABLES
-- ─────────────────────────────────────────────────────────────────────────────

create table public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  author_id uuid references public.gym_members(id) on delete cascade not null,
  post_type text check (post_type in ('achievement','pr','workout_complete','notice','coach_tip','general')) default 'general',
  content text,
  media_urls text[] default '{}',
  related_workout_id uuid references public.workout_sessions(id),
  related_pr_id uuid references public.personal_records(id),
  likes_count int default 0,
  comments_count int default 0,
  is_pinned boolean default false,
  created_at timestamptz default now()
);

create index idx_feed_gym on public.feed_posts(gym_id, created_at desc);
create index idx_feed_pinned on public.feed_posts(gym_id, is_pinned, created_at desc);

create table public.post_likes (
  post_id uuid references public.feed_posts(id) on delete cascade,
  member_id uuid references public.gym_members(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, member_id)
);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.feed_posts(id) on delete cascade not null,
  author_id uuid references public.gym_members(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now()
);

create index idx_comments_post on public.post_comments(post_id, created_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. ACHIEVEMENTS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  member_id uuid references public.gym_members(id) on delete cascade not null,
  achievement_type text not null,
  title text not null,
  description text,
  value jsonb,
  icon_url text,
  achieved_at timestamptz default now()
);

create index idx_achievements_member on public.achievements(member_id, achieved_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CLASS / SCHEDULE TABLES (Optional but useful for gyms)
-- ─────────────────────────────────────────────────────────────────────────────

create table public.class_schedules (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid references public.gyms(id) on delete cascade not null,
  title text not null,
  description text,
  coach_id uuid references public.gym_members(id),
  day_of_week int check (day_of_week between 0 and 6),
  start_time time not null,
  duration_mins int default 60,
  max_capacity int default 20,
  location text,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table public.class_bookings (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid references public.class_schedules(id) on delete cascade not null,
  member_id uuid references public.gym_members(id) on delete cascade not null,
  booked_at timestamptz default now(),
  status text check (status in ('booked','cancelled','attended')) default 'booked',
  unique(schedule_id, member_id)
);
