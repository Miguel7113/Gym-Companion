# Modules Reference

A breakdown of every module, what it owns, and how to use its endpoints.

---

## Auth Module (`src/auth/`)

Handles member signup via OTP and staff login. The two flows are completely separate.

### Member Flow (OTP)

The member auth flow has two separate concerns that happen in sequence:

**1. Authorization check (Roster)** — Is this person allowed to use this gym's app?
**2. Authentication (Supabase OTP)** — Is this person who they claim to be?

```
POST /auth/request-otp
  Body: { gymId, email | phone, displayName? }
  → Checks GymRoster for a match
  → If no match: creates a "pending" request, returns 403
  → If match: calls Supabase to send OTP email/SMS
  → Returns 200

POST /auth/verify-otp
  Body: { gymId, email | phone, token, displayName? }
  → Verifies OTP with Supabase → gets JWT session
  → Creates User row in DB (if first time)
  → Marks GymRoster entry as "matched"
  → Returns { accessToken, refreshToken, user }
```

### Staff Flow

```
POST /auth/staff/login
  Body: { email, password }
  → Calls Supabase signInWithPassword
  → Looks up GymStaff record
  → Returns { accessToken, refreshToken, staff }

POST /auth/staff/invite
  Body: { gymId, email, password, role? }
  Guard: StaffAuthGuard (must be existing staff)
  → Creates Supabase Auth user
  → Creates GymStaff row in DB
  → Returns staff record
```

### Guards

**`SupabaseAuthGuard`** — Use on member routes. Validates JWT, looks up `User` in DB, attaches to `request.member`.

```ts
@UseGuards(SupabaseAuthGuard)
myEndpoint(@CurrentMember() member: { userId, gymId, authProviderId }) {}
```

**`StaffAuthGuard`** — Use on staff-only routes. Validates JWT, looks up `GymStaff` in DB, attaches to `request.staff`.

```ts
@UseGuards(StaffAuthGuard)
myEndpoint(@CurrentStaff() staff: { staffId, gymId, role, authProviderId }) {}
```

---

## Roster Module (`src/roster/`)

Manages the list of people authorized to use a gym's app. All endpoints require `StaffAuthGuard`.

```
POST /roster/import-csv
  Body: { gymId, csvContent }
  → Parses CSV rows
  → Upserts each row by (gymId, email) or (gymId, phone)
  → Returns { imported: N, errors: [...] }

POST /roster/entry
  Body: { gymId, email | phone, memberName?, externalMemberId? }
  → Adds single roster entry
  → Returns created/updated GymRoster row

GET /roster/pending/:gymId
  → Returns all GymRoster rows with status = "pending"

POST /roster/approve/:rosterId
  → Changes roster row status from "pending" to "unmatched"
  → Member can now sign up
```

### Roster Status States

```
unmatched  →  Member can request OTP and sign up
    ↓
matched    →  Member has signed up, User row linked
pending    →  Not on roster, raised a request; waiting for staff approval
    ↓ (after /approve)
unmatched  →  Now cleared to sign up
```

---

## Gyms Module (`src/gyms/`)

Gym metadata and aggregated stats.

```
GET /gyms
  Public. Returns all active gyms: { id, name, logoUrl, primaryColor }

GET /gyms/:id
  Public. Returns one gym by ID. 404 if not found.

GET /gyms/:id/stats
  Guard: StaffAuthGuard
  Returns: { memberCount, workoutsThisWeek, pendingApprovals }

GET /gyms/:id/members
  Guard: StaffAuthGuard
  Returns: list of User rows ordered by createdAt desc
```

---

## Workouts Module (`src/workouts/`)

Workout session logging, exercise management, and progress history. All endpoints require `SupabaseAuthGuard`.

### Exercises

```
GET /exercises?q=bench
  No auth required (guard is on controller, not method — but actually all methods in this controller need auth).
  Returns up to 50 exercises matching the search term (case-insensitive).
  Returns all exercises if no query param.

POST /exercises
  Body: { name, category? }
  Creates a custom exercise scoped to the calling user.
```

### Sessions

```
POST /workouts/sessions
  Body: { notes? }
  Creates a new session for the current user + their gym.
  Returns session with sets included.

PATCH /workouts/sessions/:id
  Body: { notes?, ended? }
  Updates notes or marks session as ended (sets endedAt).
  Returns updated session with sets.

GET /workouts/sessions?limit=20&offset=0
  Returns paginated list of the user's sessions, newest first.
  Each session includes its sets with exercise details.
```

### Sets

```
POST /workouts/sessions/:id/sets
  Body: { exerciseId, setNumber?, reps?, weightKg?, rpe? }
  Appends a set to a session. Validates session belongs to user.
  Returns created set with exercise details.
```

### Progress

```
GET /workouts/progress/:exerciseId
  Returns all sets ever logged by the user for a given exercise.
  Ordered chronologically. Used for progress charts.
  Returns: [{ date, reps, weightKg, rpe }]
```

---

## Food Module (`src/food/`)

Nutrition tracking with Open Food Facts integration. All endpoints require `SupabaseAuthGuard`.

```
GET /food/search?q=ugali
  Searches local Food table + Open Food Facts API.
  Returns combined results.

GET /food/barcode/:code
  Looks up a barcode. Checks local cache first, fetches from OFD if not found.
  Caches result in Food table.

POST /food/custom
  Body: { name, caloriesPer100g?, proteinG?, carbsG?, fatG? }
  Creates a custom food entry scoped to the user.

POST /food/logs
  Body: { foodId, loggedAt, quantityG?, mealType? }
  Logs a food item for the day.

GET /food/logs?date=2025-01-15
  Returns all FoodLog rows for the given date.

GET /food/logs/summary?date=2025-01-15
  Returns: { calories, protein, carbs, fat }
  Calculated from all logs for the day, adjusted for quantity.
```

---

## Supabase Module (`src/supabase/`)

A thin wrapper around the Supabase JS SDK. Registered as a **global module** so any service can inject `SupabaseService`.

You should not call Supabase directly in other services — always go through `SupabaseService`.

```ts
// Injecting it
constructor(private supabase: SupabaseService) {}

// Available methods
supabase.sendEmailOtp(email)
supabase.sendPhoneOtp(phone)
supabase.verifyOtp({ email?, phone?, token })     // returns Session
supabase.signInWithPassword(email, password)      // returns Session
supabase.createStaffUser(email, password)          // returns User
```

---

## Prisma Module (`src/prisma/`)

Wraps the Prisma client. Registered as a **global module**. Handles connection lifecycle (`onModuleInit` / `onModuleDestroy`).

Inject `PrismaService` anywhere you need database access:

```ts
constructor(private prisma: PrismaService) {}

// Then use it directly
this.prisma.user.findUnique({ where: { id } })
this.prisma.workoutSession.create({ data: { ... } })
```
