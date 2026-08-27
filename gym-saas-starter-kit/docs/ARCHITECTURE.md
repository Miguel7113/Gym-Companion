# Architecture Overview

## Multi-Tenancy Model

Every table in the database has a `gym_id` column. This is the **tenant isolation key**. Row Level Security (RLS) policies ensure that a member of Gym A can never see data from Gym B.

### Tenant Isolation Flow

```
Member opens app
    │
    ▼
Selects gym (by name search or code entry)
    │
    ▼
Enters email/phone → Edge Function checks gym_members table
    │
    ▼
If found & active → Supabase sends OTP
    │
    ▼
Member enters OTP → Edge Function verifies + links auth user
    │
    ▼
JWT now contains: { gym_id, member_id, role }
    │
    ▼
Every DB query uses RLS: WHERE gym_id = jwt->gym_id
```

## Authentication Architecture

### Two Separate Auth Flows

| Flow | Users | Method | Purpose |
|------|-------|--------|---------|
| **Member Auth** | Gym members | OTP (Email/SMS) | Mobile app login |
| **Staff Auth** | Gym owners/managers/coaches | Email + Password | Admin portal |

### Why Two Flows?

- **Members** should not need to remember passwords. OTP is frictionless for gym-goers.
- **Staff** need persistent sessions for dashboard work. Email+password is standard for B2B SaaS.
- **Security isolation**: A staff account compromise does not affect member accounts.

### The "Claim" Pattern

Since gym admins pre-register members, the auth flow is an **account claim**, not a sign-up:

1. Admin uploads CSV → `gym_members` rows created (no `auth_user_id`)
2. Member opens app → enters email/phone
3. Edge Function verifies the row exists for that gym
4. Supabase sends OTP
5. Member verifies OTP → `auth_user_id` is populated → account is "claimed"
6. On subsequent logins, the existing `auth_user_id` is validated against the JWT

## Data Flow Diagrams

### Workout Session Flow

```
Member starts workout
    │
    ▼
INSERT workout_sessions (gym_id, member_id, started_at)
    │
    ▼
Member logs sets
    │
    ▼
INSERT workout_sets (session_id, exercise_id, reps, weight_kg...)
    │
    ▼
Compare to personal_records table
    │
    ├─▶ If PR: INSERT personal_records → TRIGGER → INSERT feed_posts (type='pr')
    │
    ▼
Member ends workout
    │
    ▼
UPDATE workout_sessions SET ended_at = now()
    │
    ▼
TRIGGER: INSERT feed_posts (type='workout_complete')
```

### Feed Interaction Flow

```
Member opens Feed tab
    │
    ▼
SELECT * FROM feed_posts WHERE gym_id = ? ORDER BY created_at DESC
    │
    ▼
Supabase Realtime subscription on feed_posts (gym_id = ?)
    │
    ▼
New post arrives → Auto-insert into Flutter list (no pull-to-refresh)
    │
    ▼
Member likes post
    │
    ▼
INSERT post_likes → TRIGGER → UPDATE feed_posts.likes_count
    │
    ▼
Optimistic UI update in Flutter (instant feedback)
```

## Edge Functions

| Function | Purpose | Auth Required |
|----------|---------|---------------|
| `auth-request-otp` | Validates member exists in gym, rate limits, triggers Supabase OTP | No |
| `auth-verify-otp` | Verifies OTP, links auth user on first claim, refreshes JWT with gym claims | No |
| `admin-import-members` | Bulk CSV import with gym limit checks, duplicate handling | Yes (staff JWT) |
| `push-notify` | Sends FCM push notifications to member devices | Yes (staff JWT) |

## Security Model

### Row Level Security (RLS)

Every table has RLS enabled. Policies use helper functions that read from the JWT claims:

```sql
-- Helpers injected into every policy
create function get_current_gym_id() returns uuid
  -- Reads: request.jwt.claims->>'gym_id'

create function get_current_member_id() returns uuid
  -- Reads: request.jwt.claims->>'member_id'

create function get_current_user_role() returns text
  -- Reads: request.jwt.claims->>'role'
```

### Key Security Rules

1. **No Service Role Key in client code** — Edge Functions use it server-side only
2. **Gym subscription status checked on every OTP request** — Expired gyms are locked out
3. **Member must be pre-registered** — Random emails cannot request OTPs
4. **Rate limiting** — Max 3 OTP requests per 10 minutes per contact
5. **Account takeover prevention** — If `auth_user_id` already exists, it must match the verifying user
6. **Staff actions verified** — Admin portal actions check `gym_staff` table, not just `auth.users`

## Scaling Considerations

### Current (Supabase-only)
- Auth, database, storage, edge functions, realtime — all on Supabase
- Suitable for 0-50 gyms, ~10,000 members

### Future (Add Google Cloud)
- **Cloud Run**: Custom microservices (e.g., video processing for exercise demos)
- **BigQuery**: Analytics warehouse for gym engagement metrics
- **Cloud Scheduler**: Nightly reports, cleanup jobs
- **Cloud CDN**: Serve exercise GIFs/images globally

## File Organization Philosophy

### Mono-repo Structure

```
gym-saas-platform/
├── packages/core/          # Shared Dart models (mobile + any future Flutter web)
├── apps/mobile/            # Flutter app
├── apps/admin-web/         # Next.js portal
└── supabase/               # Migrations, functions, config
```

**Why mono-repo?**
- Single PR can update schema + mobile + web simultaneously
- Shared `packages/core` prevents model drift
- One CI/CD pipeline orchestrates all deployments
- Supabase migrations live in one authoritative place
