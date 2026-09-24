# Workout Module — Step-by-Step Build Plan

Covers everything needed to take the Train screen from static mockup to a fully working feature: Supabase, backend, and Flutter. Follow in order — each phase depends on the one before it.

---

## Phase A — Supabase / Database

- [ ] **A1.** Create `.env` in the backend from `.env.example`, fill in your Supabase project's `DATABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (Supabase dashboard → Project Settings → API)
- [ ] **A2.** Run `npm install` in the backend project
- [ ] **A3.** Run `npm run prisma:generate`
- [ ] **A4.** Run `npm run prisma:migrate` — this creates `exercises`, `workout_sessions`, `workout_sets`, `workout_plans`, `plan_weeks`, `plan_sessions`, `plan_assignments`, and adds the `gender` column to `users`
- [ ] **A5.** Open Supabase Table Editor and confirm all 7 new tables exist with the expected columns
- [ ] **A6.** Run `npx prisma validate` locally as a final schema sanity check (couldn't be run in the sandbox that generated this — do it once on your machine before relying on the schema)

---

## Phase B — Backend: Workouts Module (already built — verify it runs)

- [ ] **B1.** Run `npm run start:dev`, confirm it boots with no errors
- [ ] **B2.** Test `GET /workouts/exercises` with a valid bearer token (from a completed OTP login) — should return `[]` until Phase C seeds it
- [ ] **B3.** Test `POST /workouts/sessions` → should create a session and return it
- [ ] **B4.** Test `POST /workouts/sessions/:id/sets` → confirm the response shape is `{ set, isPr }`, not a bare set object
- [ ] **B5.** Confirm every route in `workouts.controller.ts` is behind `@UseGuards(SupabaseAuthGuard)` — a request with no/invalid token should get a 401

---

## Phase C — Seed the Exercise Library (ExerciseDB — confirmed good fit)

The `Exercise` model now mirrors ExerciseDB's actual structure (`exerciseId`, `name`, `gifUrl`, `targetMuscles`, `bodyParts`, `equipments`, `secondaryMuscles`, `instructions`) rather than a single `category` field — this is what enables real muscle-group browsing, not just a handful of filter chips.

- [ ] **C1.** Deploy the open-source ExerciseDB (self-hosted version, one-click to Vercel) — pulls from a JSON dataset into a Supabase table
- [ ] **C2.** Write a one-off seed script mapping ExerciseDB's JSON 1:1 into our `exercises` table:
  ```
  externalId       <- exerciseId
  name             <- name
  gifUrl           <- gifUrl
  bodyParts        <- bodyParts
  targetMuscles    <- targetMuscles
  secondaryMuscles <- secondaryMuscles
  equipments       <- equipments
  instructions     <- instructions
  isCustom         <- false
  createdByUserId  <- null
  ```
  Also derive a coarse `category` (strength/cardio/hiit/mobility) per exercise at seed time — a simple lookup table keyed by `bodyParts`/`equipments` is enough (e.g. anything with `equipments: ["body weight"]` and `bodyParts` including cardio-associated parts → "cardio"), just for the existing Train screen filter chips. Don't overthink this mapping — it's a convenience label, `bodyParts` is the field that actually matters for filtering.
- [ ] **C3.** Confirm `GET /workouts/exercises/body-parts` returns the full list of muscle groups now in your library — this powers the muscle-diagram grid on the exercise tab
- [ ] **C4.** Confirm `GET /workouts/exercises?bodyPart=chest` and `?category=strength` both filter correctly

## Phase D — Backend: Plans/Programs Module (schema updated — module still not built)

`WorkoutPlan` now supports categories/tags, authorship (official/member/coach), visibility, and popularity signals (uses count, rating) — matching a real "Programs" discovery experience (Popular Programs, Recommended for You, star ratings, download counts), not just a single admin-assigned template.

- [ ] **D1.** `plans.service.ts` — build following the same pattern as `workouts/`:
  - `browsePublic({ category, sortBy })` — powers "Popular Programs" (sort by `usesCount`) and category browsing
  - `getRecommended(userId)` — simplest v1 version: plans matching the user's `targetAudience`/gender default, sorted by rating; don't over-engineer real recommendation logic yet
  - `createPlan(userId, authorRole, dto)` — lets a member OR a coach create and publish a plan; `authorRole` determines the badge shown in discovery
  - `assignDefaultPlan(userId, gender)` — as before
  - `getActivePlan(userId)` / `getTodaysSession(userId)` — as before
  - `ratePlan(userId, planId, stars)` — updates `ratingSum`/`ratingCount`
- [ ] **D2.** `plans.controller.ts` — routes: `GET /plans` (browse, with `?category=` and `?sort=popular|rating`), `GET /plans/recommended`, `GET /plans/active`, `GET /plans/today`, `POST /plans` (create/publish), `POST /plans/:id/assign`, `POST /plans/:id/rate`
- [ ] **D3.** All routes behind `SupabaseAuthGuard`; `visibility: "gym"` plans must filter by the requester's `gymId`
- [ ] **D4.** Decide on moderation for member/coach-created plans before opening this up publicly — even a lightweight "flag for review" is worth having from day one, same principle as the social feed's moderation queue
- [ ] **D5.** Seed a handful of real official plans by hand (8-week "Strength Foundation," a "Full Body" beginner plan, a "4-Day Split") — content work, not automatable

---

## Phase E — Flutter: Wire Existing Screens to Real Data

- [ ] **E1.** Confirm `api_client`'s base URL points at your running backend (`http://localhost:3000` for local dev, or your device's equivalent if testing on a physical phone)
- [ ] **E2.** Replace the hardcoded "Strength Foundation, Week 3/8, 60%" on the Train screen with a real call to `GET /plans/active`
- [ ] **E3.** Replace the hardcoded workout cards (Upper Body Power, Metabolic Burn) with `GET /workouts/exercises` — or, more accurately, with a "browsable workouts" list once Phase D's plan-session data exists
- [ ] **E4.** Replace the raw `DioException` error screen (per the earlier fix) with the friendly error+retry pattern, now genuinely necessary since these calls hit a real backend that can fail
- [ ] **E5.** Wire "Recent Workouts" to `GET /workouts/sessions`

---

## Phase F — Flutter: Active Workout Session Screen (new — the main deliverable)

- [ ] **F1.** Design in Stitch using the prompt already written for this screen (elapsed timer, per-exercise set tables, exercise picker, rest timer, inline PR indicator)
- [ ] **F2.** Build the screen shell: sticky header (live elapsed time + End Workout), scrollable exercise list
- [ ] **F3.** "Add Exercise" picker: searchable list + category filter, calling `GET /workouts/exercises`
- [ ] **F4.** Set logging row: reps/weight/RPE inputs, calls `POST /workouts/sessions/:id/sets`, reads `isPr` from the response to show the inline PR badge immediately
- [ ] **F5.** "Last time" hint: call `GET /workouts/exercises/:id/progress`, show the most recent entry beneath the input row before the user logs a new set
- [ ] **F6.** Rest timer: local countdown (no backend call needed), auto-starts after each set is logged, dismissible
- [ ] **F7.** "End Workout" → `PATCH /workouts/sessions/:id` with `{ ended: true }` → navigate to the existing Workout Complete screen, passing session totals (duration, volume, set count, PR summary) computed from the session data already in memory

---

## Phase G — Flutter: Gender-Based Plan Defaults (onboarding)

- [ ] **G1.** Add a gender selection step to the signup/setup flow — always with a neutral "prefer not to say" option, framed as picking a starting template, not a permanent category
- [ ] **G2.** On completing setup, call `POST /plans/:id/assign` (or a simpler `POST /users/me/onboarding-complete` that internally calls `assignDefaultPlan`) using the selected value
- [ ] **G3.** Confirm the user can change their assigned plan freely afterward from a "Browse Plans" screen — this should never feel locked in

---

## Phase H — Additional Features (build after E/F/G are solid, roughly in this order)

- [ ] **H1.** Per-exercise progress chart (line graph, using the `/progress` endpoint — already returns the right shape)
- [ ] **H2.** 1RM estimate on exercise detail (Epley formula: `weight × (1 + reps/30)`)
- [ ] **H3.** Plate calculator (target weight + bar weight → plates to load per side)
- [ ] **H4.** "Copy last workout" — prefill a new session from a past one
- [ ] **H5.** Superset/circuit grouping in the session UI
- [ ] **H6.** Deload week logic (every 4th week, suggest reduced volume) — simple rule, not ML
- [ ] **H7.** Drag-to-reorder exercises within an active session

---

## Phase I — Testing Checklist Before Calling This Done

- [ ] Start a session, log 3+ sets across 2+ exercises, end it — confirm totals on Workout Complete match what was logged
- [ ] Log a weight higher than any previous entry for an exercise — confirm `isPr: true` and the badge shows
- [ ] Try logging a set with no internet connection — confirm the friendly error state shows, not a raw exception
- [ ] Confirm a brand-new user with no history sees no "last time" hint (not a crash or blank error)
- [ ] Confirm switching plans after onboarding actually changes what shows on the Train/Home screens
- [ ] Confirm a member from Gym A can never see or log against Gym B's data (spot-check a couple of endpoints manually)
