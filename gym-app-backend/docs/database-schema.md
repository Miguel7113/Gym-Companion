# Database Schema

Canonical definition: `prisma/schema.prisma` in this package.  
Website-oriented summary: `docs/archive/tether-plan/TETHER_Database_and_API.md` (repo root).

All IDs are UUIDs. PostgreSQL is hosted on Supabase (local Postgres may be used in some dev setups).

---

## Entity relationship (current)

```
Gym
├── GymStaff
├── GymRoster ──► User (matched)
├── User
│     ├── WorkoutSession ──► WorkoutSet ──► Exercise
│     ├── WorkoutTemplate (routines)
│     ├── Post / likes / comments / flags
│     ├── CoachCertification (as coach)
│     ├── UserAchievement
│     └── PushToken / UserSession
└── Post / CoachCertification / WorkoutSession (gym_id)
```

**v1:** one `users.gym_id` per member (no `user_gyms`).  
**v1 feed:** gym-wide posts (no follows).  
Food / meal-plan tables were removed (migration `007`).

---

## Tables

### `gyms`

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| name | String | |
| logoUrl | String? | |
| primaryColor | String? | White-label accent |
| timezone | String | Default `UTC` |
| contactEmail | String? | |
| subscriptionTier | String | Default `trial` |
| isActive | Boolean | Default true |
| createdAt / updatedAt | DateTime | |

### `gym_staff`

Staff for admin portal / `isStaff` checks.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK → gyms |
| email | String | Unique |
| role | String | Default `admin` |
| authProviderId | String? | Supabase Auth user id |
| createdAt / updatedAt | DateTime | |

### `gym_roster`

Pre-approved members before/during signup.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK |
| email / phone | String? | At least one in practice |
| memberName | String? | |
| externalMemberId | String? | Gym’s own ID |
| status | String | `unmatched` / `matched` / `pending` |
| matchedUserId | String? | Linked user |
| createdAt | DateTime | |

Unique: `(gymId, email)`, `(gymId, phone)`.

### `users`

Members after claim. **Single gym.**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK — not multi-gym |
| rosterId | String? | |
| email / phone | String? | |
| displayName | String? | |
| gender | String? | |
| bodyWeightKg / heightCm | Decimal? | |
| subscriptionTier | String | Default `free` |
| authProviderId | String? | Unique |
| createdAt / updatedAt | DateTime | |

### Workouts

- `exercises` — global + custom (`isCustom`, media, muscles, instructions)
- `workout_sessions` — `userId`, `gymId`, optional `templateId`, soft `deletedAt`
- `workout_sets` — strength + cardio fields, soft `deletedAt`
- `workout_templates` + `workout_template_exercises` — routines/programs
- `saved_exercises`, `saved_programs`, `recently_used_exercises`

### Social

- `posts` — optional unique `workoutSessionId`, `imageUrl`/`imagePath`, flags/deleted
- `post_likes`, `post_comments`, `post_flags`
- `coach_certifications` — one per post

### Infra

- `user_sessions` — refresh token rows
- `push_tokens` — device tokens (send pipeline TBD)
- `user_achievements` — PRs / milestones

---

## Not in schema (deferred / rejected for v1)

`profiles`, `user_gyms`, `user_follows`, `gym_notices`, `reports`, `notifications`, `gym_analytics`.

Notices in the Flutter UI are still placeholders — choose typed staff posts vs a new notices table before implementing.

---

## Access pattern

NestJS uses Prisma with the database URL / service role as configured. Clients send Supabase JWTs; NestJS enforces gym scoping. RLS policies in `supabase/migrations/` are secondary hardening.
