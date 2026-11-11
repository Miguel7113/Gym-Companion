# Supabase Migrations

This folder contains SQL migrations for the Tether database schema. Migrations are run manually in the Supabase SQL Editor (not via automated tools).

## Migration Order

| # | File | Description | Status |
|---|------|-------------|--------|
| 002 | `002_workout_module.sql` | Workout sessions, sets, exercises — Phase 1 core tables | ✅ Applied |
| 003 | `003_phase2_social.sql` | Social feed: posts, post_likes, post_comments | ✅ Applied |
| 004 | `004_workout_builder.sql` | Workout templates, saved exercises/programs, cardio fields | ✅ Applied |
| 005 | `005_social_flags.sql` | Post flagging system (post_flags table) | ✅ Applied |
| 006 | `006_rls_policies_v1.sql` | Early Row Level Security (superseded by 009) | ✅ Applied |
| 007 | `007_storage_buckets.sql` | Supabase Storage buckets (avatars, gym-assets, post-images) | ✅ Applied |
| 008 | `008_drop_food.sql` | **Drops food/nutrition tables** — feature shelved | ✅ Applied |
| 009 | `009_rls_policies.sql` | **Complete RLS** with JWT helpers for all tables | ✅ Applied |
| 010 | `010_workout_media_certification.sql` | Coach certification for workout posts | ✅ Applied |
| 011 | `011_routine_session_link.sql` | Links workout_sessions to workout_templates via `template_id` FK | ✅ Applied |
| 012 | `012_gym_timezone.sql` | Adds timezone column to gyms table | ✅ Applied |
| 013 | `013_gym_notices.sql` | Gym announcements (gym_notices table) | ✅ Applied |
| 014 | `014_coach_buddies_notifications.sql` | Buddy linking + in-app notifications | ✅ Applied |
| 015 | `015_avatars_bucket.sql` | Avatar storage bucket configuration | ✅ Applied |
| 099 | `099_phase3_ai_payments.sql` | **Future** — AI conversations, payments, data import (not applied) | ❌ Phase 3 |

## How to Apply Migrations

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → SQL Editor
2. Copy the contents of a migration file
3. Paste and run
4. Mark the migration as applied in this table

## Important Notes

### Migration 001 (Missing)
There is no `001_*` file. The initial schema (gyms, users, gym_staff, gym_roster) was created manually before migrations were tracked.

### Food Feature (Migration 008)
The nutrition/food tracking feature was shelved in Sept 2024. Migration 008 drops all food-related tables. See `docs/phase2-plan.md` appendix for details.

### RLS Policies (006 vs 009)
- `006_rls_policies_v1.sql` — Early, incomplete RLS
- `009_rls_policies.sql` — Current, complete RLS with JWT helper functions

If setting up a fresh database, you can skip 006 and only run 009.

### Phase 3 (Migration 099)
Migration 099 creates tables for AI companion, payments, and data import features. It's numbered 099 to indicate it's future/unused. Do not run until Phase 3 development starts.

## Renaming History

**Oct 2024:** Migrations renumbered to fix duplicate prefixes:
- `003_workout_builder.sql` → `004_workout_builder.sql`
- `004_social_flags.sql` → `005_social_flags.sql`
- All subsequent migrations shifted up by +1 or +2
- `004_phase3_ai_payments.sql` → `099_phase3_ai_payments.sql` (future)

**Why:** Having two `003_*` and two `004_*` files caused confusion and would break automated migration tools.

## Adding New Migrations

1. Use the next sequential number (currently: 016)
2. Name format: `NNN_brief_description.sql`
3. Add a comment block at the top explaining what the migration does
4. Update this README table
5. Test the migration on a dev/staging database before production
