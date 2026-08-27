# Backend Architecture Overview

## Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js + TypeScript |
| Framework | NestJS |
| ORM | Prisma |
| Database | PostgreSQL (hosted on Supabase) |
| Auth Provider | Supabase Auth |
| HTTP Validation | class-validator + class-transformer |

---

## Project Structure

```
src/
├── app.module.ts          # Root module — imports all feature modules
├── main.ts                # App entry point — global pipes, CORS, port
│
├── auth/                  # Authentication & authorization
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── auth.module.ts
│   ├── supabase-auth.guard.ts   # Guard for member routes
│   ├── staff-auth.guard.ts      # Guard for staff routes
│   ├── decorators/
│   │   └── current-user.decorator.ts
│   └── dto/
│
├── roster/                # Gym member roster management
├── gyms/                  # Gym metadata + stats
├── workouts/              # Workout session + exercise tracking
├── food/                  # Nutrition tracking
├── supabase/              # Supabase Auth SDK wrapper (global)
└── prisma/                # Prisma client wrapper (global)
```

---

## Multi-Tenancy

Every member-facing table is scoped by `gym_id`. A member belongs to exactly one gym. Staff can belong to one gym. All queries filter by `gymId` to keep tenants isolated.

```
Gym → GymStaff (staff accounts)
    → GymRoster (authorized members)
    → User (signed-up members)
         → WorkoutSession → WorkoutSet
         → FoodLog
```

---

## Request Lifecycle

```
HTTP Request
  ↓
NestJS Router
  ↓
Guard (SupabaseAuthGuard or StaffAuthGuard)
  │  - Reads Authorization: Bearer <JWT>
  │  - Verifies token with SUPABASE_JWT_SECRET
  │  - Looks up User or GymStaff in DB
  │  - Attaches member/staff context to request
  ↓
Controller
  │  - Reads context via @CurrentMember() or @CurrentStaff()
  │  - Validates request body via DTO + ValidationPipe
  ↓
Service
  │  - Business logic
  │  - Prisma queries
  ↓
Response (JSON)
```

---

## Global Setup (main.ts)

```ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,           // strips unknown fields
  forbidNonWhitelisted: true,// throws on unknown fields
  transform: true,           // coerces types (string → number etc.)
}));
app.enableCors();
```

---

## Module Dependency Graph

```
AppModule
├── ConfigModule (global)
├── PrismaModule (global)
├── SupabaseModule (global)
├── AuthModule
│   └── RosterModule (forwardRef — circular dep avoidance)
├── RosterModule
│   └── AuthModule (forwardRef)
├── GymsModule
│   └── AuthModule
├── WorkoutsModule
│   └── AuthModule
└── FoodModule
    └── AuthModule
```

Every feature module imports `AuthModule` to access the guards. `AuthModule` and `RosterModule` use `forwardRef()` because `AuthService` calls `RosterService` during the signup flow, and `RosterModule` needs `AuthModule` for its guards.

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key for admin Auth operations |
| `SUPABASE_JWT_SECRET` | Used by guards to verify incoming JWTs |
| `PORT` | HTTP server port (default 3000) |

---

## Key Design Principles

1. **Front-ends are thin** — All business logic lives in the backend. Mobile and admin portal call this API; they never hit the DB directly.
2. **Module ownership** — Each module owns its own tables. Cross-module communication goes through service injection, not raw Prisma queries from other modules.
3. **UUID primary keys** — All tables use UUIDs. Stable across migrations and multi-tenant operations.
4. **Separation of concerns** — Roster (authorization: "is this person allowed in?") is completely separate from OTP verification (authentication: "is this person who they say they are?").
5. **No per-gym code branches** — One codebase handles all gyms via `gymId` scoping.
