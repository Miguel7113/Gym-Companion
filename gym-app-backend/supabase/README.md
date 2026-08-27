# Supabase Migrations

Run these SQL files in the Supabase Dashboard → SQL Editor, in order.

## How to run

1. Go to your Supabase project → **SQL Editor** → **New query**
2. Paste the contents of each file and click **Run**
3. Run them in numbered order — each file depends on the previous

---

## Migration files

| File | When to run | What it does |
|------|-------------|--------------|
| `001_initial_schema.sql` | **Now** | All Phase 1 tables: gyms, staff, roster, users, exercises, workout sessions/sets. **Food/nutrition tables excluded** — they will be added in a separate migration once the food API is chosen so the schema can match the API's data structure. |
| `002_schema_gaps.sql` | **Now** | Fixes: missing updated_at columns, soft-delete columns, adds user_sessions, push_tokens, user_achievements |
| `005_rls_policies.sql` | **Now** | Row Level Security on all Phase 1 + 2 tables |
| `006_storage_buckets.sql` | **Now** | Creates avatars, gym-assets, post-images, import-files buckets with access policies |
| `003_phase2_social.sql` | When starting social feed | posts, post_likes, post_comments tables |
| `007_phase2_nutrition_workout.sql` | When starting Phase 2 nutrition/workout features | User goals, streaks, water logs, meal templates, workout templates |
| `004_phase3_ai_payments.sql` | When starting Phase 3 | AI conversations/messages, subscriptions, payment events, import jobs |

---

## Run order for right now (Phase 1 setup)

```
001 → 002 → 005 → 006
```

## Run order for Phase 2

```
003 → 007
```

## Run order for Phase 3

```
004
```

---

## Notes

- Your NestJS backend uses the **service_role key** which bypasses RLS entirely — the policies in 005 only protect against someone hitting the DB directly with an anon or user key.
- The `update_updated_at_column()` trigger function is created in migration 001. All subsequent migrations reuse it.
- Storage bucket policies in 006 use `storage.foldername()` to enforce per-user folder structure: e.g. `avatars/{userId}/profile.jpg`
