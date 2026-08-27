# Gym App Backend — Phase 1 Scaffold (Auth + Roster)

## What's included
- NestJS project structure with Prisma (Postgres via Supabase) and Supabase Auth (OTP).
- `auth` module: `/auth/request-otp` and `/auth/verify-otp` — implements the
  two-step signup flow (roster authorization + OTP authentication).
- `roster` module: CSV bulk import, manual entry, pending-approval queue —
  used by the admin portal.
- `.cursor/rules/` — project rules so Cursor's AI stays consistent with this
  architecture as you build out the remaining modules.
- `docs/build-plan.md` — the full project plan (architecture, costs, schema, roadmap).

## Setup
1. `npm install`
2. Copy `.env.example` to `.env` and fill in your Supabase project's
   `DATABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (Project Settings → API
   in the Supabase dashboard).
3. `npm run prisma:generate`
4. `npm run prisma:migrate` — creates the `gyms`, `gym_roster`, and `users`
   tables in your Supabase Postgres database.
5. `npm run start:dev` — runs on `http://localhost:3000`.

## Signup flow (what the Flutter app will call)
1. User picks their gym, enters email or phone →
   `POST /auth/request-otp` `{ gymId, email }`
   - Returns `otp_sent` if they're on the gym's roster,
     `pending_approval` if not (gym staff approve via `/roster/pending/:gymId`
     and `/roster/approve/:rosterId`),
     or `already_registered` if an account already exists.
2. User enters the code they received →
   `POST /auth/verify-otp` `{ gymId, email, token, displayName }`
   - Creates the `users` row linked to their gym and roster entry.

## Next module to build
`workouts` — see docs/build-plan.md section 9 (Step 5). Follow the same
folder pattern as `roster/` (module, controller, service, dto/).
