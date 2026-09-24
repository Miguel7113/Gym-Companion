# Gym Companion App — Full Build Plan
### Dawn Digital | Multi-tenant fitness app for gyms

---

## 1. Product Scope (as I understand it)

**Core app (client-facing, mobile):**
- Workout logging (exercises, sets/reps/weight, history, progress charts)
- Calorie & food tracking (barcode scan + database lookup + manual entry)
- AI workout/nutrition companion (chat-based coaching)
- Music suggestions matched to workout type/intensity
- Social tab — gym-scoped feed of member highlights/achievements
- Paid tiers (free / premium, possibly gated AI)

**Admin portal (web, per-gym):**
- Gym staff manage their members, view engagement, post announcements, moderate the social feed, configure branding

**Multi-tenant requirement:**
- One core codebase, deployable as a white-labeled app per gym (own logo/colors/name) while sharing all backend logic

I'll flag one thing now: you mentioned git branches for gym-specific versions. **I'd steer you away from that** — branches diverge and merging bug fixes across 10 gym branches becomes a nightmare fast. The industry-standard approach for this exact problem (white-labeling) is **build flavors/schemes** (Flutter has this natively) driven by a single config file or a remote config service, still one branch. I've built the plan around that instead — it'll save you months of pain later.

---

## 2. Recommended Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Mobile app | **Flutter** | One codebase → iOS + Android, native performance, built-in "flavors" for white-labeling, matches what you already scoped for the food app |
| Admin portal | **Next.js (React)** | You already have this in your stack; fast to build dashboards, deploys easily |
| Backend API | **NestJS (TypeScript)** | Same language as the Next.js admin portal (one less context switch for a solo dev); its module/service structure maps directly onto our module breakdown (auth, roster, workouts, etc.) |
| Database | **PostgreSQL** | Relational data (users, gyms, workouts, food logs) — this is a textbook relational-data app |
| Auth | **Supabase Auth or Firebase Auth** | Don't build your own auth. Use a managed provider. |
| File/image storage | **Supabase Storage or AWS S3** | Profile pics, achievement photos |
| Push notifications | **Firebase Cloud Messaging (FCM)** | Free, works for both iOS/Android |
| AI companion | **Anthropic API (Claude) or OpenAI API** | Pay-per-token, no infra to run |
| Music suggestions | **Spotify Web API** | Free tier, well-documented (details below — there's a catch) |
| Food/nutrition data | **Open Food Facts (free) + Nutritionix (paid) fallback** | Open Food Facts alone is often "good enough" and free — start there |
| Hosting | **Railway, Render, or a DigitalOcean droplet** for backend; **Vercel** for the Next.js admin portal | Cheap, simple CI/CD |

---

## 3. Feature-by-Feature Technical Notes

### 3.1 Workout Logging
- Data model: `exercises` (master list), `workout_sessions`, `sets` (exercise_id, reps, weight, rpe, session_id)
- Seed your own exercise database (or use a free one like **wger's** open exercise database as a starting seed — check its license) rather than building 500 exercises by hand.
- Progress charts: just query historical sets per exercise — no special service needed, render with `fl_chart` (Flutter) or `recharts` (web admin).

### 3.2 Calorie & Food Tracking
- Barcode scanning: use **Google ML Kit** (free, on-device, works offline) for the scan itself.
- Food database: **Open Food Facts API is free and open-source** — start here. It has gaps in African/local food coverage, so budget time to let users manually add common local foods (ugali, sukuma wiki, chapati, etc.) to a local "custom foods" table that grows organically — this is actually a competitive advantage for a Nairobi-first app, since global apps (MyFitnessPal etc.) are weak on East African foods.
- Nutritionix ($49–$249/mo) is only worth adding later if user feedback says the free database isn't cutting it.

### 3.3 AI Companion
- Don't build this as "always-on chat with unlimited history" — token costs scale directly with conversation length. Cap context sent per message (e.g., last 10 messages + a summary of the user's recent workout/food data).
- Use **Claude Haiku or GPT-4o-mini** class models for this, not the top-tier models — coaching chat doesn't need frontier reasoning, and cost is ~10-20x lower.
- Gate it as premium-only from day one; it's your clearest paid-tier differentiator and it's the feature with a real per-use cost, so it needs to map to revenue.

### 3.4 Music Suggestions
- **Important catch**: The Spotify Web API can *look up* tracks, audio features (tempo/energy/danceability), and build playlists — free, no cost. But actually *playing* music in-app requires the user to have **Spotify Premium** and use the Spotify SDK to control their own Spotify player. You can't stream licensed music yourself without a very expensive label licensing deal.
- Realistic MVP version: "Here's a Spotify playlist matched to your workout" → deep-links into their Spotify app. Don't try to build in-app playback of licensed music; that's a different company's problem to solve (literally what Spotify's a partner for).
- Apple Music equivalent requires a $99/yr Apple Developer account (which you need anyway) plus MusicKit — same deep-link approach applies.

### 3.5 Social Tab (gym-scoped)
- Straightforward: `posts` table scoped by `gym_id`, likes/comments, moderation flag for gym admins.
- Keep this simple in v1 — a feed + like button + report button. Resist scope creep here (stories, DMs, etc.) until you have real gyms using it.

### 3.6 Admin Portal
- Gym staff need: member list, engagement stats (logins, workouts logged this week), a way to push announcements, and moderation controls for the social feed.
- Also needs: **branding config screen** — this is what feeds your white-label build (gym uploads logo, picks primary color, sets gym name) — stored in your DB and pulled at app build time or via remote config at runtime.

### 3.7 Multi-Tenant / White-Label Architecture
Two possible approaches — pick based on how "separate" each gym's app needs to feel:

1. **One shared app, gym selected at login** (cheapest, fastest, one App Store listing) — user picks/is assigned their gym after signup. No white-labeling at all beyond in-app theming.
2. **Per-gym app builds using Flutter flavors** — each gym gets their own icon/name/App Store listing, but it's the same codebase built with different config. This is what you described wanting. Requires a **separate Apple/Google developer listing per gym** (cost implication below) and a small build script per release.

Given your stage, I'd genuinely recommend **starting with option 1** (single app, "select your gym" screen) to get to market and validate, and only move to option 2 once a gym specifically asks for their own branded app as a condition of signing — which may never actually come up. This is the same validation-first instinct you used on the food app idea, and it applies here too: white-labeling infrastructure is pure cost until a paying customer asks for it.

---

## 3.8 Gym Roster Login (member matching)

This needs two separate mechanisms, not one — a common mistake is to treat "matches the roster" as the same thing as "proved they own that email/phone," which would let anyone type in a real member's email and get into their account.

**Mechanism 1 — Authorization (are they actually a member?)**
- Gym admin uploads a **roster**: a CSV (or manual entry) of `email`, `phone`, `member_name`, `external_member_id` into a `gym_roster` table, scoped to `gym_id`.
- This can be re-synced any time membership changes (new joiners, cancellations).

**Mechanism 2 — Authentication (do they own that contact info?)**
- On signup: user picks their gym → enters email or phone.
- Backend checks the `gym_roster` table for a match on `(gym_id, email)` or `(gym_id, phone)`.
- **If matched**: send an OTP code or magic link to that email/phone (via Supabase/Firebase Auth) — this proves ownership, not just that they typed a string that happens to be in your database. Only after OTP verification do they get an account linked to that gym.
- **If not matched**: don't reject outright — create a "pending request" that notifies the gym admin in the portal to manually approve. This handles rosters that are out of date or incomplete without locking people out.

**Data model addition:**
```
gym_roster: id, gym_id, email, phone, member_name, external_member_id, matched_user_id (nullable), status (unmatched/matched/pending)
```

**Edge cases worth deciding early (not necessarily building for on day one):**
- What happens when a gym removes someone from the roster — downgrade access, don't hard-delete their logged data (they may still want it, or may switch gyms).
- One person belongs to two gyms — decide whether a user account is gym-exclusive or can hold multiple gym memberships. I'd default to **one primary gym per account** for v1; it's simpler and matches how most gym-branded apps work.

---

## 3.9 Importing Data From Other Apps

Realistic approach: **build one generic importer, not N app-specific ones.**

- **Generic CSV importer** — user uploads any CSV, your UI shows their columns and lets them map each one to your fields (date, exercise name, weight, reps / food name, calories, etc.). This is the single highest-leverage thing to build because it works for *any* export, including ones you've never heard of.
- **Native importers for the biggest, best-documented sources**, added only if demand shows up:
  - **Strong** and **Hevy** (popular lifting-log apps) both support clean CSV export with a known schema — worth a dedicated parser since it removes the mapping step entirely for those users.
  - **Apple Health** exports a large XML file (via "Export Health Data" in iOS) that contains both workouts and some nutrition data — needs an XML parser, a bit more work but very common source.
  - **MyFitnessPal** does not have easy self-serve export — most users would fall back to your generic CSV importer here, so don't sink extra effort chasing MFP specifically.
- **Processing**: run imports as a background job, not inline — a multi-year import shouldn't block the UI. At your scale, a simple `import_jobs` table + a cron worker that processes queued rows is enough; you don't need a heavyweight queue system yet.
- **Deduplication**: hash each imported row (date + exercise + weight, or date + food + calories) so re-running an import doesn't create duplicates.

---

## 4. Cost Breakdown

### 4.1 One-time / Fixed Costs

| Item | Cost |
|---|---|
| Apple Developer Program (annual) | $99/yr |
| Google Play Console (one-time) | $25 |
| Domain name (e.g., yourapp.com) | ~$12–15/yr |
| Business registration in Kenya (if not already done via Dawn Digital) | KES ~10,000–15,000 (~$75–115) one-time |
| App icon / basic brand design (if not DIY) | $0 if you design it, $50–200 if outsourced |

### 4.2 Monthly Running Costs — by scale

**Stage A: Pilot / Validation (1 gym, <200 users)**
| Service | Cost/mo |
|---|---|
| Backend hosting (Railway/Render starter) | $5–20 |
| PostgreSQL (managed, small) | $0–15 (often bundled with above) |
| Supabase (auth+storage+DB combined, free tier) | $0 |
| Firebase (push notifications, free tier) | $0 |
| AI API (Claude Haiku, ~200 users, moderate use) | $10–40 |
| Open Food Facts | $0 (free/open) |
| Spotify API | $0 |
| Domain + misc | ~$2 |
| **Total** | **~$20–80/mo** |

**Stage B: Growth (3–10 gyms, ~1,000–5,000 users)**
| Service | Cost/mo |
|---|---|
| Backend hosting (upgraded tier) | $25–75 |
| Postgres (managed, dedicated) | $25–60 |
| Supabase Pro (if outgrown free tier) | $25 |
| AI API costs (scales with usage) | $100–400 |
| Nutritionix (if added) | $49–249 |
| Image/file storage | $5–20 |
| Error tracking (Sentry, free–small tier) | $0–26 |
| **Total** | **~$230–855/mo** |

**Stage C: Scale (10,000+ users across many gyms)**
This is where you'd move to dedicated infrastructure (AWS/GCP with autoscaling), likely $1,500–5,000+/mo depending on AI usage specifically (this is usually the largest and most variable line item — meter it closely).

### 4.3 Transaction/Payment Costs
If you charge via M-Pesa (Daraja API): no API fee to Safaricom for basic integration, but transaction charges apply per Safaricom's published tariffs (varies by amount tier) — you'll need a Paybill/Till number, which has its own KES setup and monthly costs depending on which tier you register (Lipa Na M-Pesa vs. full Paybill).
If you also want card payments (for gyms/users outside Kenya or preferring cards): Stripe or Flutterwave, typically ~2.9% + a fixed fee per transaction.

### 4.4 What's genuinely free at your stage
- Flutter, Next.js, Node.js/Python — all free, open-source
- GitHub (private repos free for individuals)
- GitHub Actions CI/CD (2,000 free minutes/mo)
- Firebase Auth/Push/Analytics — free tier covers you well past pilot stage
- Open Food Facts database
- ML Kit barcode scanning

---

## 5. Suggested Build Order (Solo Developer Timeline)

Since you're coding this yourself alongside client work, realistic pacing matters more than an idealized sprint plan.

**Phase 0 — Validate (2–4 weeks, no code)**
Before building anything: pitch 1–2 gyms on the concept. Confirm they'd actually want to offer this to members and would pay something for it. This mirrors exactly the validation approach we discussed for the food app — cheap to test, expensive to skip.

**Phase 1 — MVP (8–12 weeks)**
- Auth + gym selection
- Workout logging (core feature, build this first — it's your retention driver)
- Basic food logging (Open Food Facts + manual entry)
- Basic admin portal (member list + basic stats only)
- No AI, no music, no social yet

**Phase 2 — Engagement Layer (4–6 weeks)**
- Social tab (gym-scoped feed)
- Music suggestion deep-links (Spotify)
- Push notifications for streaks/achievements

**Phase 3 — Premium/AI Layer (4–6 weeks)**
- AI companion (gated to premium)
- Payment integration (M-Pesa)
- Admin portal: branding config, announcements, moderation tools

**Phase 4 — Multi-tenant white-labeling (only if a gym asks)**
- Build flavor setup, per-gym app store listings

Total to a real, sellable MVP: roughly **4–5 months** part-time, assuming Phase 0 confirms real demand.

---

## 6. Legal / Compliance Notes (don't skip this)

- Fitness and food-log data counts as **personal/health-adjacent data** under Kenya's **Data Protection Act (2019)**. If you're processing this data for gyms as clients, you likely need to register with the **Office of the Data Protection Commissioner (ODPC)** as a data controller/processor once you're operating at any real scale — worth a short consult rather than guessing.
- Have a real Privacy Policy and Terms of Service before launch — free generators exist but get someone with legal knowledge to sanity-check it once you have paying gyms, since you're now a data processor for their members.
- If any gym is outside Kenya later, GDPR (EU) considerations apply too — cross that bridge only if it comes up.

---

## 7. Monetization Shape (worth deciding early)

Most natural fit given your B2B2C model:
- **Gyms pay you** a monthly/annual license fee to offer the app to their members (this is your main revenue line)
- **Members get free access** to the app as a perk of their gym membership (this is the sales pitch to gyms — "give your members a premium fitness app at no cost to them")
- **Optional member-paid premium tier** (AI companion, advanced analytics) as an upsell, revenue-shared with the gym or kept by you — decide this with your first pilot gym, don't lock it in before you have one real conversation with a gym owner about what they'd actually pay for.

---

## 8. Summary Cost Table (Year 1 realistic estimate)

| Category | Low estimate | High estimate |
|---|---|---|
| Developer accounts (Apple + Google) | $124 | $124 |
| Domain | $12 | $15 |
| Hosting/DB/Auth/Storage (pilot → growth) | $240/yr | $2,000/yr |
| AI API costs | $120/yr | $4,800/yr |
| Nutrition API (if needed) | $0 | $3,000/yr |
| Business registration | $75 | $115 |
| **Total Year 1** | **~$570** | **~$10,000+** |

The wide range is almost entirely driven by AI usage and how many gyms/users you have — everything else is genuinely cheap at your stage.

---

## 9. Step-by-Step: How to Actually Start This Week

This is deliberately sequential — each step unlocks the next, and building out of order (e.g., social feed before auth) is the most common way solo devs stall out.

**Step 1: Validate before writing code (this week)**
- Get one real conversation with one gym owner. Show them a rough sketch (even just a Figma mockup or a one-pager) of: workout logging, food tracking, social feed, and roster-based login. Confirm: would they actually roll this out to members, and would they pay for it?
- Ask specifically how they currently store member emails/phones (spreadsheet? some gym management software?) — this tells you what format the roster import needs to handle in real life, not in theory.

**Step 2: Set up your foundations (days 1–3 of build)**
- Create the GitHub repo (one repo, one main branch — no gym-specific branches).
- Scaffold Flutter app with build flavor structure in place from day one (`dev`, `staging`, `prod`) even though you're only using `prod` for now — retrofitting flavors later is more painful than starting with them.
- Scaffold Next.js admin portal.
- Provision Supabase project (gives you Postgres + Auth + Storage in one place — good default at your stage).
- Set up GitHub Actions for basic CI (lint + build check) — free tier covers you.

**Step 3: Design your full DB schema before writing feature code**
- Core tables: `gyms`, `gym_roster`, `users`, `workouts`, `workout_sets`, `exercises`, `food_logs`, `foods`, `posts` (social), `import_jobs`.
- Get this on paper (or an ERD tool) and sanity-check relationships before coding — schema changes are cheap now, expensive after you have real user data.
- I can draft the actual SQL schema for you as a next step if useful — just say the word.

**Step 4: Build auth + roster matching end-to-end first**
- This gates literally everything else, so build it completely (signup, OTP verification, roster match, pending-approval fallback) before touching workout logging.
- Test it with a fake CSV roster of 5–10 emails you control.

**Step 5: Build the core retention loop — workout logging**
- This is the feature people will open the app for daily. Get logging + history + basic progress chart working end-to-end before food tracking or social.

**Step 6: Build minimal admin portal**
- Just enough for a real gym to use: upload roster CSV, view member list, approve pending requests.

**Step 7: Add food tracking (Open Food Facts + manual entry)**

**Step 8: Pilot with the one gym from Step 1**
- Real roster, real members, real data import test using someone's actual export from Strong/Apple Health/a spreadsheet. This will surface edge cases (duplicate emails, malformed CSVs, members with no email on file) faster than any amount of planning will.

**Step 9: Layer in social tab, music suggestions, AI companion, payments** — in whatever order the pilot gym's feedback tells you matters most.

**Step 10: Only then consider white-label/multi-tenant builds** — if and when a second or third gym specifically asks for their own branded app.

---

## 10. Build Approach: Simple Base First, Not Full Design First

Design the whole thing up front and you're designing against guesses — you don't yet know which features gyms actually value (that's what the Step 1 pilot conversation is for). Build a **vertical slice** instead: one feature (auth + workout logging) working end-to-end through every layer, looking plain, then add features one at a time. Do one real design/polish pass once you know — from a real pilot gym — what actually matters. Redesigning after feedback is normal; designing everything before feedback usually means throwing work away.

---

## 11. Code Architecture — What Links to What

### 11.1 System Map

```
┌─────────────────┐        ┌──────────────────┐
│   Flutter App    │        │  Next.js Admin    │
│  (gym members)   │        │   (gym staff)     │
└────────┬─────────┘        └────────┬──────────┘
         │  HTTPS / REST (JSON)      │  HTTPS / REST (JSON)
         └─────────────┬─────────────┘
                        ▼
              ┌───────────────────┐
              │   Backend API      │
              │     (NestJS)        │
              │  ─────────────────  │
              │  auth module        │
              │  gyms module        │
              │  roster module      │
              │  workouts module    │
              │  food module        │
              │  social module      │
              │  ai module          │
              │  imports module     │
              │  notifications mod. │
              └─────────┬───────────┘
                        │
        ┌───────────────┼───────────────────────────┐
        ▼               ▼                           ▼
┌───────────────┐ ┌─────────────┐          ┌──────────────────┐
│  PostgreSQL     │ │  Storage     │          │  External APIs    │
│  (Supabase)     │ │ (Supabase/S3)│         │  ────────────────  │
│  all app data   │ │ images, CSVs │          │  Spotify Web API   │
└───────────────┘ └─────────────┘          │  Claude/OpenAI API │
                                              │  Open Food Facts   │
                                              │  Firebase (push)   │
                                              │  M-Pesa Daraja API │
                                              └──────────────────┘
```

Both the Flutter app and the Next.js admin portal talk **only to your backend API** — never directly to the database or third-party services. This is the one rule worth being strict about from day one: it means auth checks, roster-matching logic, and rate-limiting on the AI companion all live in one place instead of being duplicated (and inevitably done inconsistently) in two front-ends.

### 11.2 Backend Structure (modules, each roughly a folder)

- `auth/` — signup, login, OTP verification, session/token handling
- `gyms/` — gym CRUD, branding config, gym-level settings
- `roster/` — CSV upload/parsing, roster matching logic, pending-approval queue
- `workouts/` — exercises, sessions, sets, progress queries
- `food/` — food logs, Open Food Facts proxy/cache, custom local foods
- `social/` — posts, likes, comments, moderation flags
- `ai/` — companion chat endpoint, context-building, token/cost tracking per user
- `imports/` — generic CSV importer, Strong/Hevy/Apple Health parsers, import job queue
- `notifications/` — push notification triggers (streaks, achievements, gym announcements)
- `payments/` — M-Pesa/Stripe integration, subscription status

Each module should expose a small, clear API surface (a handful of endpoints) and own its own database tables — resist the temptation to let, say, the `social` module reach directly into `workouts` tables. If it needs workout data, it calls the `workouts` module's internal service function. This is what keeps a solo-maintained codebase sane as it grows.

### 11.3 Flutter App Structure (feature-based, not layer-based)

```
lib/
  core/
    api_client.dart        (single HTTP client, auth token attached here)
    theme/                 (colors, typography — this is what flavors override)
  features/
    auth/
    workouts/
    food/
    social/
    ai_companion/
    profile/
  flavors/
    dev/
    prod/
main_dev.dart
main_prod.dart
```
- One `api_client` wrapping all backend calls — every feature folder uses it, never calls `http` directly. This is what makes swapping/mocking the backend painless during development.
- State management: pick one (Riverpod is a solid default for a solo dev — less boilerplate than Bloc, more structure than plain Provider) and use it consistently across all features rather than mixing approaches per screen.

### 11.4 Next.js Admin Portal Structure

```
app/
  (auth)/login
  dashboard/
  members/          → roster upload, pending approvals, member list
  posts/            → social feed moderation
  branding/          → logo/colors config
  settings/
lib/
  api.ts            (single API client, mirrors Flutter's api_client)
```

### 11.5 The One Architectural Rule Worth Committing To Early
**Front-ends are dumb, backend is smart.** Both the Flutter app and admin portal should mostly just display data and collect input — roster matching, OTP verification, AI cost-tracking, and social moderation rules all live in the backend. If you ever build a second client (say, a web version of the member app), this rule is what saves you from re-implementing your business logic twice.

---

## 12. Postgres Schema (v1 — start here)

Notes before the tables:
- `uuid` primary keys throughout — easier to merge/import data later than auto-increment ints, and safer once you have multiple gyms generating data independently.
- Every member-facing table carries `gym_id` — this is what makes the whole thing multi-tenant without needing separate databases per gym. Almost every query in your backend will filter by `gym_id`, so index it everywhere.
- Timestamps (`created_at`, `updated_at`) omitted below for brevity but add them to every table.

```sql
-- ===== GYMS & STAFF =====

CREATE TABLE gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  primary_color TEXT,
  contact_email TEXT,
  subscription_tier TEXT DEFAULT 'trial',  -- trial / basic / premium
  is_active BOOLEAN DEFAULT true
);

CREATE TABLE gym_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID REFERENCES gyms(id) NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT DEFAULT 'admin',  -- admin / moderator
  password_hash TEXT          -- or omit if using Supabase Auth entirely
);

-- ===== ROSTER & USERS =====

CREATE TABLE gym_roster (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID REFERENCES gyms(id) NOT NULL,
  email TEXT,
  phone TEXT,
  member_name TEXT,
  external_member_id TEXT,     -- their ID in the gym's own system, if any
  status TEXT DEFAULT 'unmatched',  -- unmatched / matched / pending
  matched_user_id UUID,        -- filled in once linked to a real user
  UNIQUE (gym_id, email),
  UNIQUE (gym_id, phone)
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID REFERENCES gyms(id) NOT NULL,
  roster_id UUID REFERENCES gym_roster(id),
  email TEXT,
  phone TEXT,
  display_name TEXT,
  subscription_tier TEXT DEFAULT 'free',  -- free / premium
  auth_provider_id TEXT        -- Supabase/Firebase auth user id
);

-- ===== WORKOUTS =====

CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,             -- push / pull / legs / cardio etc.
  is_custom BOOLEAN DEFAULT false,
  created_by_user_id UUID REFERENCES users(id)  -- null for seed data
);

CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  gym_id UUID REFERENCES gyms(id) NOT NULL,
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  notes TEXT
);

CREATE TABLE workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES workout_sessions(id) NOT NULL,
  exercise_id UUID REFERENCES exercises(id) NOT NULL,
  set_number INT,
  reps INT,
  weight_kg NUMERIC,
  rpe NUMERIC             -- perceived effort, optional
);

-- ===== FOOD / NUTRITION =====

CREATE TABLE foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  source TEXT,             -- 'open_food_facts' / 'custom'
  external_id TEXT,        -- barcode or OFF product id
  calories_per_100g NUMERIC,
  protein_g NUMERIC,
  carbs_g NUMERIC,
  fat_g NUMERIC,
  is_local_custom BOOLEAN DEFAULT false,
  created_by_user_id UUID REFERENCES users(id)
);

CREATE TABLE food_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  food_id UUID REFERENCES foods(id) NOT NULL,
  logged_at TIMESTAMP NOT NULL,
  quantity_g NUMERIC,
  meal_type TEXT            -- breakfast/lunch/dinner/snack
);

-- ===== SOCIAL =====

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID REFERENCES gyms(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  content TEXT,
  image_url TEXT,
  achievement_type TEXT,     -- pr / streak / milestone / null
  is_flagged BOOLEAN DEFAULT false
);

CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  UNIQUE (post_id, user_id)
);

CREATE TABLE post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  content TEXT NOT NULL
);

-- ===== AI COMPANION =====

CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL
);

CREATE TABLE ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES ai_conversations(id) NOT NULL,
  role TEXT NOT NULL,        -- user / assistant
  content TEXT NOT NULL,
  token_count INT            -- track for cost monitoring
);

-- ===== DATA IMPORT =====

CREATE TABLE import_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  source_type TEXT,          -- generic_csv / strong / hevy / apple_health
  status TEXT DEFAULT 'pending',  -- pending / processing / completed / failed
  raw_file_url TEXT,
  rows_processed INT DEFAULT 0,
  rows_total INT,
  error_log TEXT
);
```

**Indexes worth adding immediately** (skip these and things get slow fast once a gym has real usage):
```sql
CREATE INDEX idx_workout_sessions_user ON workout_sessions(user_id);
CREATE INDEX idx_workout_sets_session ON workout_sets(session_id);
CREATE INDEX idx_food_logs_user_date ON food_logs(user_id, logged_at);
CREATE INDEX idx_posts_gym ON posts(gym_id);
CREATE INDEX idx_gym_roster_gym ON gym_roster(gym_id);
```

This schema deliberately leaves out `payments`/subscription-detail tables and gym-branding-detail fields beyond the basics — add those once Phase 3 (premium/payments) is actually underway rather than designing them now against guesses.

---

## 13. Cursor AI Guardrails

Cursor's current system for persistent project context is a **`.cursor/rules/` directory of `.mdc` files** (the older single `.cursorrules` file at the project root still works, but the directory approach gives you more control — separate rules for backend vs. Flutter vs. admin portal, each only loaded when relevant). Commit this folder to git — it's project documentation that happens to also steer the AI.

### 13.1 Root-level rule — always applied

Create `.cursor/rules/architecture.mdc` with `alwaysApply: true` — this is the one rule loaded into every single request, so keep it tight and only put non-negotiables here:

```markdown
---
description: Core architecture rules — always apply
alwaysApply: true
---

# Project: Gym Companion App (Dawn Digital)

## Non-negotiable architecture rules
- Front-ends (Flutter app, Next.js admin portal) NEVER call the database or
  third-party APIs (Spotify, Open Food Facts, Claude/OpenAI, M-Pesa) directly.
  They only call our own backend API.
- The backend is organized into modules: auth, gyms, roster, workouts, food,
  social, ai, imports, notifications, payments. A module owns its own tables.
  If module A needs data from module B, it calls B's service function —
  never queries B's tables directly.
- All tables use UUID primary keys. Every member-facing table has a gym_id
  column for multi-tenancy — never create a table that mixes gyms without one.
- We do NOT use git branches per gym. Multi-tenant/white-label work uses
  build flavors (Flutter) and a shared codebase, one main branch.
- Before creating a new database table or API endpoint, check
  /docs/schema.sql and /docs/architecture.md (the project plan) first —
  do not invent new tables or endpoints that duplicate existing ones.

## When unsure
If a request conflicts with the schema in /docs/schema.sql, or would require
a new top-level module, stop and ask before generating code.
```

*(Put the schema and this build plan in a `/docs` folder in the repo root — referencing real files by path is far more reliable than re-describing your architecture in prose each time.)*

### 13.2 Scoped rules — only load for relevant files

`.cursor/rules/backend.mdc`:
```markdown
---
description: Backend API conventions
globs: ["backend/**/*.ts"]
---

- Stack: NestJS (TypeScript), Postgres via Supabase, class-validator DTOs.
- Every endpoint must validate input with a DTO/schema before touching
  the database — no raw request bodies passed to queries.
- Every new table needs a matching migration file — never hand-edit
  the schema directly against a running database.
- Roster matching logic lives ONLY in the roster module. Auth module
  calls it — auth does not reimplement matching logic.
- Do not add new npm packages without flagging it in chat first.
```

`.cursor/rules/flutter.mdc`:
```markdown
---
description: Flutter app conventions
globs: ["mobile/**/*.dart"]
---

- State management: Riverpod, used consistently — do not mix in Provider,
  Bloc, or setState-heavy patterns in new features.
- All backend calls go through lib/core/api_client.dart — never call
  http/dio directly from a feature folder.
- Folder structure is feature-based (lib/features/<feature>/), not
  layer-based. New features get their own folder, not scattered files.
- Flavor config (dev/prod) must not be hardcoded into feature code —
  read from the flavor config layer.
```

`.cursor/rules/admin-portal.mdc`:
```markdown
---
description: Next.js admin portal conventions
globs: ["admin/**/*.tsx", "admin/**/*.ts"]
---

- All backend calls go through lib/api.ts — mirrors the Flutter api_client
  pattern. Never fetch() directly from a component.
- Roster CSV upload UI should surface per-row errors (bad email, duplicate)
  rather than failing the whole upload silently.
```

### 13.3 Workflow habits that matter more than the rules themselves

Rules only help if you use Cursor in a way that respects them:

1. **Give it one module or feature at a time, not "build the app."** "Build the roster module: upload CSV, match against users table, expose a GET endpoint for pending approvals" gets you reviewable, correct code. "Build the backend" gets you a plausible-looking mess that doesn't match your schema.
2. **Point it at the actual files, not a description.** Reference `/docs/schema.sql` and existing modules explicitly in your prompts ("follow the same pattern as workouts/workouts.service.ts") rather than re-explaining conventions from memory each time — Cursor follows existing code patterns better than prose descriptions of patterns.
3. **Read every diff before accepting, especially schema changes.** It's easy to let Composer/Agent mode run across multiple files and rubber-stamp the result. A wrong foreign key or a new table that duplicates `foods` is much cheaper to catch in the diff than after you've built three features on top of it.
4. **Commit after every working feature, not at the end of the day.** If an AI-driven multi-file change goes sideways, you want a clean rollback point. Small, frequent commits are your safety net here more than with hand-written code, since Cursor can change more surface area per action than a human typically would.
5. **Ask it to write a test alongside new logic that matters** — roster matching and AI cost-tracking especially, since bugs there are either a security issue (wrong-person access) or a money issue (runaway token usage).
6. **When it proposes a new table, endpoint, or package, treat that as a decision point, not a suggestion to auto-accept** — cross-check against section 12 (the schema) and section 11 (the module map) before saying yes. This is exactly what the `alwaysApply` rule above is meant to prevent, but rules can still be missed, so a human check matters too.
7. **Keep the plan doc and schema file updated as you go.** If you deviate from the original schema during a session, update `/docs/schema.sql` right after — a stale reference doc is worse than no reference doc, because Cursor will confidently follow the wrong one.

---

## 14. Version Roadmap — Features, Infra, and When

This consolidates everything above into one place to check before starting each phase. The general principle: **each version should be justified by something you learned in the previous one**, not by "it would be nice to have."

### v1.0 — Pilot (single gym, prove the concept)
**Features:**
- Auth (roster matching + OTP) — already scaffolded
- Roster admin (CSV upload, pending approvals) — already scaffolded
- Workout logging (core loop: log sets, view history/progress)
- Admin portal: member list, roster upload, pending approvals only

**Infra:**
- Supabase **free tier** covers Auth + Postgres + Storage entirely at this scale
- Backend hosting: Railway/Render **free or ~$5/mo starter tier**
- Admin portal: Vercel **free tier**
- No AI, no payments, no push notifications yet — nothing here should cost real money beyond pocket change

**Exit criteria for this version:** one real gym is using it with real members logging real workouts, and you've had at least one round of feedback from actual usage (not hypothetical).

---

### v1.1 — Food Tracking
**Features:** food logging via Open Food Facts + manual/custom local foods (ugali, sukuma wiki, etc. as discussed)
**Infra:** no change — still within Supabase free tier at this scale

---

### v1.2 — Engagement Layer
**Features:**
- Social tab (gym-scoped feed, likes, moderation flag)
- Push notifications (streaks, achievements, gym announcements)
- Music suggestions (Spotify deep-link, not in-app playback)
- Admin portal: social moderation tools

**Infra:**
- Firebase Cloud Messaging added (free)
- Spotify Web API added (free)
- Still likely within Supabase free tier, but check storage usage (achievement post images) — this is the first place you might need to watch a limit

---

### v1.3 — Premium & Monetization
**Features:**
- AI companion (Claude/OpenAI API, gated to premium tier, capped context per message as discussed)
- Payments (M-Pesa Daraja API)
- Admin portal: branding config, subscription status per member

**Infra:**
- This is where real variable cost enters (AI token usage) — this is the point to start watching the `token_count` tracking in `ai_messages` closely, per member and per gym
- Supabase: likely time to move to **Pro tier (~$25/mo)** if you've onboarded a few gyms by now
- Backend hosting: likely time to move to a **paid starter tier (~$25-75/mo)** if request volume has grown

**Exit criteria:** you have at least one gym paying you, and a read on whether members actually use the AI companion enough to justify its cost.

---

### v1.4 — Data Import
**Features:** generic CSV importer with column mapping, native Strong/Hevy parsers, Apple Health XML import
**Infra:** `import_jobs` background worker (simple cron-based queue is enough at this scale, no need for RabbitMQ/SQS yet)

**Why this comes this late, not in v1.0:** import only matters once you have real users switching from another app — building it before you have a pilot gym means designing against a guess about what format their old data is actually in.

---

### v2.0 — Offline-First Sync
**Features:**
- Local database on the Flutter app (Drift is the closest Flutter equivalent to what WatermelonDB does for React Native — schema-first, type-safe, well-suited to mirroring the Prisma-defined backend schema)
- Sync engine: queue writes made offline, push to backend on reconnect, `updated_at` timestamp-based conflict resolution (last-write-wins is fine at this scale — don't over-engineer this)
- Applies mainly to workout logging and food logging — the two things someone would plausibly do with no signal at the gym

**Infra:** no new hosted service needed — this is entirely client-side work plus small additions to existing API endpoints (accept a batch of queued writes with timestamps)

**Why this is v2, not v1:** it's real engineering complexity (conflict resolution, sync state) for a problem you haven't confirmed exists yet — most gyms have wifi. Build this once a pilot gym's members actually report logging failures from poor signal, not before.

---

### v2.x — Multi-Tenant White-Label
**Features:** Flutter build flavors activated for real, separate app store listings per gym, admin portal support for franchise/multi-location gyms
**Infra:** additional Apple/Google developer listing costs per branded app (App Store review time also multiplies per listing — budget for this)

**Why this is v2.x, not v1:** as covered earlier, this is pure cost until a specific gym asks for it as a condition of signing.

---

### v3.0 — Scale
**Features:** deeper admin analytics/reporting, multi-gym membership support if it comes up, anything else surfaced by real usage at this point rather than guessed now
**Infra:** move off Supabase/Railway free-and-starter tiers to dedicated infrastructure (dedicated Postgres instance, autoscaling backend) once user count and AI usage justify it — likely the ~$1,500-5,000+/mo range from the Stage C cost table in section 4.2

---

### Summary Table

| Version | Key features | New infra/cost |
|---|---|---|
| v1.0 | Auth, roster, workout logging, basic admin | Free tier everything |
| v1.1 | Food tracking | No change |
| v1.2 | Social, push, music | FCM + Spotify (free) |
| v1.3 | AI companion, payments | AI API cost begins; Supabase/hosting likely go paid |
| v1.4 | Data import | Background job worker |
| v2.0 | Offline sync | Client-side only, no new hosted service |
| v2.x | White-label | Per-gym developer listing costs |
| v3.0 | Scale/analytics | Dedicated infra |

---

## 15. Review Notes: Gaps Closed Before Building Further

### 15.1 Session Authentication (the real gap)
OTP verification proves identity at signup, but nothing so far defines how a **subsequent** request (view workouts, post to social feed) proves who's calling. Fix:
- After `verify-otp` succeeds, the Supabase session already includes a JWT — return it to the Flutter app and have `api_client.dart` attach it as `Authorization: Bearer <token>` on every request from then on.
- Add a NestJS guard (`SupabaseAuthGuard`) that validates this JWT on every protected route and attaches the resolved `userId`/`gymId` to the request — every module (`workouts`, `food`, `social`, etc.) depends on this existing before it can trust who's making a request.
- This guard is a **prerequisite for the `workouts` module**, not an add-on — build it next, before workouts.

### 15.2 Gym Staff Login (admin portal)
The `gym_staff` table exists but has no auth flow. Needed before the admin portal (Step 6) is usable:
- Simplest v1 approach: gym staff also authenticate via Supabase (email + password or magic link — OTP-only makes less sense for a portal used repeatedly from a desk), with a separate `StaffAuthGuard` checking against `gym_staff` rather than `users`.
- Keep this genuinely separate from member auth — a staff account should never be checkable against the member `gym_roster` matching logic; conflating the two is a security bug waiting to happen.

### 15.3 Gym Onboarding
Nothing yet creates the first `Gym` row. For v1.0 with a single pilot gym, the pragmatic answer is: **you create it manually** (a seed script or a one-off Prisma Studio insert) rather than building a self-serve "gym signup" flow — that flow is real work that only matters once you're onboarding gyms 2, 3, 4... without your direct involvement. Note it as deliberately manual for now, not accidentally missing.

### 15.4 Build Order Update
Given 15.1, the actual next step is the **auth guard**, not the workouts module directly — it's a small addition to the existing `auth` module, then workouts follows immediately after using it.

---

## 16. Design System Reference (from the Pulse Stitch mockups)

**Established visual language — keep consistent across every new screen:**
- Color: near-black background, neon lime accent used ONLY for primary/active/positive states (CTAs, progress bars, active filter chips, likes). Nothing else uses this color.
- Typography: bold condensed display face for headlines; small-caps monospace-style labels for all stats/tags/metadata (weights, durations, macros, timestamps).
- Photography: desaturated, cool-toned, dark-overlaid gym photography — keep this grading consistent on any new or AI-generated images.
- Icons: thin-outline style throughout (Lucide recommended, already in the stack) — don't mix in filled/duotone icons later.
- Branding tokens: accent color and logo should be designed as swappable tokens (not hardcoded), since gym white-labeling will need to override them.

**Decisions made from this review:**
- Login/signup uses OTP only — no password field, no forgot-password flow. Matches the backend already built.
- Meal-logging button states (logged / active / locked) need an explicit visual rule, not just color variation.

**Screens still needed, in build order:**
1. Active workout session (set/rep/weight entry, rest timer) — highest priority, most-used screen
2. Exercise detail/library
3. Workout history / progress charts
4. Pending-approval ("waiting on your gym") state
5. Profile/settings
6. Food search + add-meal, barcode scanner
7. PR/achievement celebration screen (worth extra design polish — this is the social loop's core emotional moment)
8. Notifications center
9. AI companion chat
10. Premium upgrade/paywall
11. Payment (M-Pesa) screen
