# Database Schema Reference

## Table Index

| Table | Purpose | RLS |
|-------|---------|-----|
| `gyms` | Tenant (gym) records | ✅ |
| `gym_members` | Pre-registered gym members | ✅ |
| `gym_staff` | Admin portal users | ✅ |
| `otp_logs` | OTP request rate limiting | ✅ |
| `push_tokens` | FCM device tokens | ✅ |
| `exercises` | Exercise library | ✅ |
| `workout_templates` | Workout programs | ✅ |
| `workout_template_exercises` | Exercises within templates | ✅ |
| `workout_sessions` | Logged workout instances | ✅ |
| `workout_sets` | Individual sets within sessions | ✅ |
| `personal_records` | PR tracking per exercise | ✅ |
| `feed_posts` | Social feed posts | ✅ |
| `post_likes` | Post likes | ✅ |
| `post_comments` | Post comments | ✅ |
| `achievements` | Achievement badges | ✅ |
| `class_schedules` | Weekly class schedule | ✅ |
| `class_bookings` | Member class bookings | ✅ |

---

## Core Tables

### `gyms`

The tenant table. Every gym pays a flat monthly fee.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default gen_random_uuid() | |
| `name` | text | NOT NULL | Display name |
| `slug` | text | UNIQUE | URL-friendly identifier |
| `code` | text | UNIQUE | Member-facing code (e.g., IRON2024) |
| `logo_url` | text | | Gym logo image |
| `primary_color` | text | DEFAULT '#FF6B35' | Brand color hex |
| `subscription_status` | text | CHECK | active, past_due, cancelled, trialing |
| `subscription_expires_at` | timestamptz | | When to lock out |
| `plan_tier` | text | DEFAULT 'standard' | basic, standard, premium |
| `max_members` | int | DEFAULT 200 | Enforced on import |
| `admin_email` | text | NOT NULL | Primary contact |
| `billing_email` | text | | Invoice recipient |
| `stripe_customer_id` | text | | Stripe Customer ID |
| `stripe_subscription_id` | text | | Stripe Subscription ID |
| `settings` | jsonb | DEFAULT {...} | Feature flags per gym |
| `created_at` | timestamptz | DEFAULT now() | |

**`settings` JSONB structure:**
```json
{
  "features": {
    "workout_tracking": true,
    "social_feed": true,
    "coach_messaging": true,
    "pr_leaderboard": true,
    "class_booking": false
  }
}
```

---

### `gym_members`

Pre-registered members. `auth_user_id` is NULL until first login claim.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK | |
| `gym_id` | uuid | FK → gyms, NOT NULL | Tenant isolation |
| `email` | text | | Unique per gym |
| `phone` | text | | E.164 format, unique per gym |
| `full_name` | text | | Display name |
| `avatar_url` | text | | Profile image |
| `date_of_birth` | date | | |
| `gender` | text | | |
| `fitness_goal` | text | | e.g., "strength", "weight_loss" |
| `experience_level` | text | DEFAULT 'beginner' | beginner, intermediate, advanced |
| `auth_user_id` | uuid | FK → auth.users | NULL until claimed |
| `role` | text | DEFAULT 'member' | member, coach, admin |
| `is_active` | boolean | DEFAULT true | Admin can deactivate |
| `claimed_at` | timestamptz | | First login timestamp |
| `last_active_at` | timestamptz | | Updated on workout |
| `metadata` | jsonb | DEFAULT '{}' | Flexible storage |

**Constraints:**
- `contact_info_required`: email OR phone must be set
- `unique(gym_id, email)`
- `unique(gym_id, phone)`

**Indexes:**
- `idx_gym_members_lookup(gym_id, email, phone)` — OTP lookups
- `idx_gym_members_auth(auth_user_id)` — Session resolution

---

### `gym_staff`

Admin portal users. Separate from gym_members.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK | |
| `gym_id` | uuid | FK → gyms, NOT NULL | |
| `auth_user_id` | uuid | FK → auth.users | |
| `email` | text | NOT NULL, UNIQUE | |
| `full_name` | text | | |
| `role` | text | DEFAULT 'coach' | owner, manager, coach |
| `is_active` | boolean | DEFAULT true | |
| `created_at` | timestamptz | DEFAULT now() | |

---

## Workout Tables

### `exercises`

Exercise library. Can be global (gym_id = NULL) or gym-specific.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms, NULL = global |
| `name` | text | NOT NULL |
| `category` | text | e.g., "strength", "cardio" |
| `body_parts` | text[] | e.g., ["chest", "shoulders"] |
| `target_muscles` | text[] | Primary muscles |
| `secondary_muscles` | text[] | Supporting muscles |
| `equipments` | text[] | e.g., ["barbell", "bench"] |
| `difficulty` | text | beginner, intermediate, advanced |
| `gif_url` | text | Demo animation |
| `instructions` | text[] | Step-by-step |
| `overview` | text | Description |
| `is_custom` | boolean | User-created vs system |
| `created_by_user_id` | uuid | FK → gym_members |
| `created_at` | timestamptz | |

---

### `workout_templates`

Reusable workout programs.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms, NULL = global |
| `created_by` | uuid | FK → gym_members (coach) |
| `name` | text | NOT NULL |
| `description` | text | |
| `category` | text | e.g., "upper_body", "hiit" |
| `difficulty` | text | |
| `duration_mins` | int | Estimated time |
| `source` | text | system, gym, user |
| `image_url` | text | Cover image |
| `is_active` | boolean | |
| `created_at` | timestamptz | |

---

### `workout_template_exercises`

Individual exercises within a template.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `template_id` | uuid | FK → workout_templates |
| `exercise_id` | uuid | FK → exercises |
| `sort_order` | int | Display order |
| `default_sets` | int | |
| `default_reps` | int | |
| `default_weight_kg` | decimal(8,2) | |
| `default_duration_secs` | int | For cardio |
| `default_distance_m` | decimal(10,2) | For cardio |
| `notes` | text | Coach notes |

---

### `workout_sessions`

A single workout instance logged by a member.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms |
| `member_id` | uuid | FK → gym_members |
| `template_id` | uuid | FK → workout_templates (optional) |
| `started_at` | timestamptz | DEFAULT now() |
| `ended_at` | timestamptz | NULL until finished |
| `notes` | text | Member notes |
| `pr_achieved` | boolean | Any PR in this session? |
| `created_at` | timestamptz | |

---

### `workout_sets`

Individual sets within a session.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `session_id` | uuid | FK → workout_sessions |
| `exercise_id` | uuid | FK → exercises |
| `set_number` | int | 1st, 2nd, 3rd set... |
| `reps` | int | |
| `weight_kg` | decimal(8,2) | |
| `rpe` | decimal(3,1) | Rate of perceived exertion |
| `assist_kg` | decimal(8,2) | Assisted weight |
| `duration_secs` | int | Cardio |
| `distance_m` | decimal(10,2) | Cardio |
| `speed_kph` | decimal(5,2) | Cardio |
| `created_at` | timestamptz | |

---

### `personal_records`

Best performance per exercise per member.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms |
| `member_id` | uuid | FK → gym_members |
| `exercise_id` | uuid | FK → exercises |
| `record_type` | text | weight, reps, distance, duration |
| `value` | decimal(10,2) | The record value |
| `unit` | text | kg, reps, m, secs |
| `session_id` | uuid | FK → workout_sessions |
| `achieved_at` | timestamptz | |

**Constraint:** `unique(member_id, exercise_id, record_type)`

---

## Social Feed Tables

### `feed_posts`

Social posts within a gym.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms |
| `author_id` | uuid | FK → gym_members |
| `post_type` | text | achievement, pr, workout_complete, notice, coach_tip, general |
| `content` | text | Post text |
| `media_urls` | text[] | Image/video URLs |
| `related_workout_id` | uuid | FK → workout_sessions |
| `related_pr_id` | uuid | FK → personal_records |
| `likes_count` | int | DEFAULT 0 |
| `comments_count` | int | DEFAULT 0 |
| `is_pinned` | boolean | DEFAULT false (for notices) |
| `created_at` | timestamptz | |

---

### `post_likes`

| Column | Type | Notes |
|--------|------|-------|
| `post_id` | uuid | FK → feed_posts |
| `member_id` | uuid | FK → gym_members |
| `created_at` | timestamptz | |

**PK:** `(post_id, member_id)`

---

### `post_comments`

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `post_id` | uuid | FK → feed_posts |
| `author_id` | uuid | FK → gym_members |
| `content` | text | NOT NULL |
| `created_at` | timestamptz | |

---

## Achievement Tables

### `achievements`

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms |
| `member_id` | uuid | FK → gym_members |
| `achievement_type` | text | e.g., "first_workout", "streak_7", "pr_10" |
| `title` | text | Display title |
| `description` | text | |
| `value` | jsonb | Flexible data |
| `icon_url` | text | Badge image |
| `achieved_at` | timestamptz | |

---

## Class Schedule Tables

### `class_schedules`

Weekly recurring classes.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `gym_id` | uuid | FK → gyms |
| `title` | text | NOT NULL |
| `description` | text | |
| `coach_id` | uuid | FK → gym_members |
| `day_of_week` | int | 0=Monday ... 6=Sunday |
| `start_time` | time | |
| `duration_mins` | int | DEFAULT 60 |
| `max_capacity` | int | DEFAULT 20 |
| `location` | text | Room/studio |
| `is_active` | boolean | DEFAULT true |
| `created_at` | timestamptz | |

---

### `class_bookings`

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `schedule_id` | uuid | FK → class_schedules |
| `member_id` | uuid | FK → gym_members |
| `booked_at` | timestamptz | DEFAULT now() |
| `status` | text | booked, cancelled, attended |

**Constraint:** `unique(schedule_id, member_id)`

---

## Auth & Utility Tables

### `otp_logs`

Rate limiting for OTP requests.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `contact` | text | Email or phone |
| `gym_id` | uuid | FK → gyms |
| `member_id` | uuid | FK → gym_members |
| `created_at` | timestamptz | DEFAULT now() |

**Index:** `idx_otp_logs_contact(contact, created_at)`

---

### `push_tokens`

FCM device tokens.

| Column | Type | Notes |
|--------|------|-------|
| `member_id` | uuid | FK → gym_members |
| `token` | text | NOT NULL |
| `platform` | text | ios, android |
| `updated_at` | timestamptz | DEFAULT now() |

**PK:** `(member_id, platform)`

---

## Triggers Summary

| Trigger | Table | Event | Function | Purpose |
|---------|-------|-------|----------|---------|
| `on_member_claimed` | `gym_members` | UPDATE | `sync_member_to_auth()` | Injects gym_id/member_id/role into JWT |
| `on_pr_created` | `personal_records` | INSERT | `handle_pr_to_feed()` | Auto-posts PR to feed |
| `on_workout_completed` | `workout_sessions` | UPDATE | `handle_workout_complete_to_feed()` | Auto-posts workout completion |
| `on_like_change` | `post_likes` | INSERT/DELETE | `update_likes_count()` | Keeps likes_count accurate |
| `on_comment_change` | `post_comments` | INSERT/DELETE | `update_comments_count()` | Keeps comments_count accurate |
| `on_session_created` | `workout_sessions` | INSERT | `update_member_last_active()` | Updates member.last_active_at |

---

## RLS Policy Summary

| Table | Policy | Operation | Rule |
|-------|--------|-----------|------|
| `gyms` | `gyms_select_own` | SELECT | `id = get_current_gym_id()` |
| `gym_members` | `members_select_own_gym` | SELECT | `gym_id = get_current_gym_id()` |
| `gym_members` | `members_update_self` | UPDATE | `gym_id = get_current_gym_id() AND id = get_current_member_id()` |
| `exercises` | `exercises_select_gym_scoped` | SELECT | `gym_id IS NULL OR gym_id = get_current_gym_id()` |
| `exercises` | `exercises_insert_coach` | INSERT | `gym_id = get_current_gym_id() AND role IN ('coach','admin')` |
| `workout_sessions` | `sessions_select_own_or_coach` | SELECT | `gym_id = get_current_gym_id() AND (member_id = get_current_member_id() OR role IN ('coach','admin'))` |
| `workout_sessions` | `sessions_insert_own` | INSERT | `gym_id = get_current_gym_id() AND member_id = get_current_member_id()` |
| `feed_posts` | `feed_select_gym_scoped` | SELECT | `gym_id = get_current_gym_id()` |
| `feed_posts` | `feed_insert_own` | INSERT | `gym_id = get_current_gym_id() AND author_id = get_current_member_id()` |
| `feed_posts` | `feed_delete_own_or_admin` | DELETE | `gym_id = get_current_gym_id() AND (author_id = get_current_member_id() OR role = 'admin')` |
