# Database Schema

All tables use UUID primary keys. The database is PostgreSQL hosted on Supabase.

---

## Entity Relationship Overview

```
Gym
 ├── GymStaff           (staff accounts for this gym)
 ├── GymRoster          (authorized member list)
 │     └── User         (signed-up members, linked from GymRoster)
 │           ├── WorkoutSession
 │           │     └── WorkoutSet
 │           │           └── Exercise (global or user-custom)
 │           └── FoodLog
 │                 └── Food (global or user-custom)
 └── (WorkoutSession also has gymId FK directly)
```

---

## Tables

### `gyms`

Represents a gym tenant.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| name | String | |
| logoUrl | String? | Optional |
| primaryColor | String? | Hex color for white-label theming |
| contactEmail | String? | |
| subscriptionTier | String | Default: `"basic"` |
| isActive | Boolean | Default: `true` |
| createdAt | DateTime | |
| updatedAt | DateTime | |

---

### `gym_staff`

Staff accounts that can log into the admin portal.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK → gyms.id |
| email | String | Unique |
| role | String | Default: `"staff"` |
| authProviderId | String | Supabase Auth `user.id` |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Index: `authProviderId`

---

### `gym_roster`

The authorization layer. Staff upload this CSV before members can sign up.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK → gyms.id |
| email | String? | At least one of email/phone required |
| phone | String? | |
| memberName | String? | |
| externalMemberId | String? | From gym's own management system |
| status | String | `"unmatched"` / `"matched"` / `"pending"` |
| matchedUserId | UUID? | FK → users.id (set when member signs up) |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Unique constraints: `(gymId, email)` and `(gymId, phone)` — prevents duplicate roster entries.

---

### `users`

Members who have signed up via OTP.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| gymId | UUID | FK → gyms.id |
| rosterId | UUID? | FK → gym_roster.id |
| email | String? | |
| phone | String? | |
| displayName | String? | |
| subscriptionTier | String | Default: `"basic"` |
| authProviderId | String | Supabase Auth `user.id` |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Indexes: `authProviderId`, `gymId`

---

### `exercises`

Shared exercise library. Seed data covers common exercises. Users can add custom ones.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| name | String | |
| category | String? | e.g. "Chest", "Back", "Legs" |
| isCustom | Boolean | `false` for seed data, `true` for user-created |
| createdByUserId | UUID? | FK → users.id (only for custom exercises) |
| createdAt | DateTime | |
| updatedAt | DateTime | |

---

### `workout_sessions`

A single gym visit/workout. A session has many sets.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| userId | UUID | FK → users.id |
| gymId | UUID | FK → gyms.id |
| startedAt | DateTime | Set on creation |
| endedAt | DateTime? | Set when PATCH with `ended: true` |
| notes | String? | Free text |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Indexes: `userId`, `gymId`

---

### `workout_sets`

A single logged set within a session.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| sessionId | UUID | FK → workout_sessions.id |
| exerciseId | UUID | FK → exercises.id |
| setNumber | Int? | Position within the session |
| reps | Int? | |
| weightKg | Decimal? | |
| rpe | Decimal? | Rate of Perceived Exertion (1–10 scale) |
| createdAt | DateTime | Used for ordering progress data |
| updatedAt | DateTime | |

Index: `sessionId`

---

### `foods`

Food item catalog. Includes seed Kenyan foods, Open Food Facts cached results, and custom user foods.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| name | String | |
| source | String? | `"openfoodfacts"`, `"local"`, `"custom"` |
| externalId | String? | Barcode (unique) |
| caloriesPer100g | Decimal? | Per 100g |
| proteinG | Decimal? | |
| carbsG | Decimal? | |
| fatG | Decimal? | |
| isLocalCustom | Boolean | Default: `false` |
| createdByUserId | UUID? | FK → users.id (for custom foods) |
| createdAt | DateTime | |
| updatedAt | DateTime | |

---

### `food_logs`

Daily nutrition log entries per user.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| userId | UUID | FK → users.id |
| foodId | UUID | FK → foods.id |
| loggedAt | DateTime | Date of the meal |
| quantityG | Decimal? | Portion size in grams |
| mealType | String? | `"breakfast"`, `"lunch"`, `"dinner"`, `"snack"` |
| createdAt | DateTime | |
| updatedAt | DateTime | |

Index: `userId`

---

## Prisma CLI Commands

```bash
# Generate the Prisma client after schema changes
npm run prisma:generate

# Create and run a new migration
npm run prisma:migrate

# Run seed data (pilot gym + foods + exercises)
npm run prisma:seed

# Open Prisma Studio (visual DB browser)
npx prisma studio
```
