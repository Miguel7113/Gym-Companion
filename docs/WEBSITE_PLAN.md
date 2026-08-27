# Pulse — Admin Portal & Website Plan

## Overview

The admin portal is a **Next.js 14** web application for gym staff to manage their gym. It connects directly to the same Supabase project as the mobile app — no separate backend needed. Row Level Security ensures staff can only access their gym's data.

This document covers:
1. Tech stack and rationale
2. Full feature plan (linked to `gym-dashboard-features.md`)
3. Implementation phases
4. How the portal connects to the existing mobile app and backend
5. Auth flow differences (staff vs members)

---

## Tech Stack

| Component | Technology | Rationale |
|---|---|---|
| Framework | Next.js 14 (App Router) | SSR for auth-protected routes, huge React ecosystem for dashboards |
| Language | TypeScript | Type safety, matches NestJS types |
| Styling | Tailwind CSS | Utility-first, rapid dashboard UI |
| UI Components | shadcn/ui | High-quality, accessible, customisable components |
| Tables | TanStack Table (React Table) | Virtual scrolling for large member lists |
| Charts | Recharts | Workout volume, member activity graphs |
| Forms | React Hook Form + Zod | Validated forms with TypeScript schemas |
| Auth | Supabase SSR (`@supabase/ssr`) | Server-side session handling |
| Payments | Stripe.js | Subscription management |
| Database | Supabase (same project as mobile app) | Single source of truth, RLS handles isolation |

---

## Project Structure

```
admin-web/
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx           # Staff email + password login
│   │   │   └── layout.tsx               # No sidebar
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx               # Sidebar + auth guard middleware
│   │   │   ├── page.tsx                 # Dashboard overview (stats cards)
│   │   │   ├── members/
│   │   │   │   ├── page.tsx             # Member table (search, filter, activate)
│   │   │   │   └── import/page.tsx      # CSV bulk upload
│   │   │   ├── feed/
│   │   │   │   └── page.tsx             # Moderate posts, create announcements
│   │   │   ├── workouts/
│   │   │   │   ├── page.tsx             # Workout template library
│   │   │   │   └── create/page.tsx      # Template builder
│   │   │   ├── notices/
│   │   │   │   └── page.tsx             # Create/manage gym announcements
│   │   │   ├── schedule/
│   │   │   │   └── page.tsx             # Class schedule management
│   │   │   └── settings/
│   │   │       ├── branding/page.tsx    # Logo, colors, gym info
│   │   │       └── billing/page.tsx     # Stripe subscription
│   │   └── api/
│   │       └── webhooks/
│   │           └── stripe/route.ts      # Stripe event handler
│   ├── components/
│   │   ├── ui/                          # shadcn/ui components
│   │   ├── data-table.tsx               # Reusable TanStack table wrapper
│   │   ├── member-import-dialog.tsx     # CSV upload + preview
│   │   ├── stats-card.tsx               # Dashboard metric tiles
│   │   ├── post-moderation-card.tsx     # Flag queue item
│   │   └── gym-switcher.tsx             # Multi-gym staff switcher
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts               # Browser Supabase client
│   │   │   ├── server.ts               # Server component client
│   │   │   └── middleware.ts           # Auth + gym context per request
│   │   ├── validations/                # Zod schemas
│   │   └── utils.ts                    # cn(), date formatters
│   └── types/
│       └── database.ts                 # Supabase-generated types
├── middleware.ts                        # Next.js middleware (runs updateSession)
├── .env.local
├── next.config.js
└── tailwind.config.ts
```

---

## Auth Flow — Staff vs Members

| | Members (Mobile App) | Staff (Admin Portal) |
|---|---|---|
| Login method | OTP (email or SMS) | Email + Password |
| Verification | NestJS → Supabase OTP | Supabase Auth directly |
| Session storage | Flutter secure storage | HTTP-only cookies (SSR) |
| Auth check | JWT on every API request | Supabase middleware per route |
| Role | `member` \| `coach` \| `admin` (in JWT) | `owner` \| `manager` \| `coach` (in `gym_staff`) |
| Table | `users` + `gym_roster` | `gym_staff` |

### Staff Login Implementation

```typescript
// src/app/(auth)/login/page.tsx
'use client'
import { createClient } from '@/lib/supabase/client'

export default function LoginPage() {
  const supabase = createClient()

  const handleLogin = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (!error) router.push('/') // middleware verifies gym_staff
  }
}
```

### Middleware (Auth Guard)

```typescript
// src/lib/supabase/middleware.ts
export async function updateSession(request: NextRequest) {
  const supabase = createServerClient(...)
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return NextResponse.redirect('/login')

  // Verify staff membership — not just any Supabase user
  const { data: staff } = await supabase
    .from('gym_staff')
    .select('gym_id, role')
    .eq('auth_provider_id', user.id)
    .single()

  if (!staff) return NextResponse.redirect('/login?error=unauthorized')

  // Attach gym context to headers for server components
  response.headers.set('x-gym-id', staff.gym_id)
  response.headers.set('x-staff-role', staff.role)
  return response
}
```

---

## Connection to Mobile App

The admin portal and mobile app share the **same Supabase project**. There is no separate data sync needed. Changes made in the portal are immediately visible in the mobile app because they read from the same database.

### Data flow examples

**Staff creates announcement in portal:**
```
Admin portal → INSERT posts (type='announcement') → Supabase DB
Mobile app   → GET /social/posts → NestJS → Supabase → returns post
Feed tab     → shows announcement with STAFF badge
Home screen  → GYM NOTICES section shows pinned announcements
```

**Staff imports members via CSV:**
```
Admin portal → calls Supabase Edge Function admin-import-members
Edge Function → upserts gym_roster rows
Member opens app → selects gym → enters email → OTP sent → first login
```

**Member logs PR in mobile app:**
```
Mobile app → POST /workouts/sessions/:id/sets → NestJS
NestJS → detects PR → creates user_achievements + posts rows
Admin portal → dashboard shows "PRs This Week" counter
```

---

## Feature Phases

### Phase 1 — Foundation (MVP)

**Goal:** Staff can log in and manage members.

1. **Setup**
   - `npx create-next-app@latest admin-web --typescript --tailwind --app`
   - Install: `@supabase/ssr`, `shadcn/ui`, `react-hook-form`, `zod`
   - Configure `.env.local` with Supabase URL + anon key

2. **Auth**
   - Staff login page (email + password)
   - Middleware that checks `gym_staff` table
   - Protected layout with sidebar

3. **Dashboard**
   - Stats cards: Total Members, Active Today, PRs This Week, New Members
   - All data from Supabase with RLS (gym-scoped automatically)

4. **Member Management**
   - Member list table with search, filter by role/status
   - Activate / deactivate members
   - CSV import (calls `admin-import-members` Edge Function)
   - Manual add member form

### Phase 2 — Content

5. **Feed Moderation**
   - View all posts in gym feed
   - Flagged posts queue (posts with `is_flagged = true`)
   - Approve (clear flag) / Remove (soft delete) actions
   - Create staff announcements (POST /social/posts via NestJS)
   - Pin/unpin notices (`is_pinned` field on posts)

6. **Notices**
   - Dedicated notices management (subset of feed with `post_type = 'notice'`)
   - Rich text editor for announcements
   - Schedule future publish (requires `published_at` column addition)
   - Category selector: Announcement / Class Update / Reminder / Event

7. **Workout Templates**
   - Browse exercise library (same 873 exercises from mobile)
   - Create gym-specific workout templates
   - Assign templates to members or make gym-wide

### Phase 3 — Operations

8. **Class Schedule**
   - Requires `class_schedules` and `class_bookings` tables (defined in starter kit schema)
   - Weekly grid view with recurring classes
   - Add/edit/remove class slots
   - Set coach, capacity, location

9. **Settings**
   - Gym branding: name, logo upload (Supabase Storage), primary colour
   - Contact email, operating hours
   - Feature flags (enable/disable social feed, etc.)

10. **Billing (Stripe)**
    - Current plan display
    - Upgrade/downgrade with Stripe Checkout
    - Invoice history
    - Stripe webhook handler for subscription events

### Phase 4 — Analytics

11. **Member Analytics**
    - Active members over time (line chart)
    - Workout frequency distribution
    - Most popular exercises at the gym
    - Member streak leaderboard

12. **Push Notifications**
    - Send targeted push to all members or segments
    - Announcement pushes linked to notice posts
    - Streak reminder automation

---

## Connecting the Systems

### Environment Variables

```bash
# admin-web/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://uqswohwqdcjlncdudhap.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_9TD5SfAXxIPWoPdirHbhYg_DBnPjBou

# Server-side only (never exposed to browser)
SUPABASE_SERVICE_ROLE_KEY=sb_secret_...    # For admin operations
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

### Staff Account Creation

Staff accounts are created differently from members — they use email+password, not OTP. The current flow:

1. Call NestJS `POST /auth/staff/invite` with `{ gymId, email, password, role }`
2. NestJS creates the Supabase auth user + `gym_staff` row
3. Staff can then log in at `admin.yourapp.com/login`

For Phase 1, staff accounts are created manually via SQL:
```sql
-- 1. Create auth user in Supabase Dashboard → Authentication → Users
-- 2. Note the UUID, then:
INSERT INTO public.gym_staff (id, gym_id, auth_provider_id, email, full_name, role)
VALUES (gen_random_uuid(), '<gym_id>', '<supabase_user_id>', 'staff@gym.com', 'Name', 'admin');
```

### API Layer Decision

The admin portal can connect to data two ways:

**Option A — Direct Supabase (recommended for portal)**
- Portal calls Supabase directly from server components
- RLS + `gym_staff` middleware handles auth automatically
- No NestJS round-trip needed for reads
- Writes that need business logic (e.g. PR detection) still go via NestJS

**Option B — Via NestJS**
- All requests go through `localhost:3000`
- More consistent with mobile app
- Easier to add business logic later
- More infrastructure to manage

**Recommendation:** Use Supabase direct for the portal (reads + simple writes), NestJS for complex operations. The mobile app already has the NestJS pattern locked in — don't change it.

---

## Database Additions Needed for Portal

These columns/tables need to be added before certain portal features work:

```sql
-- For notice scheduling (Phase 2)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;

-- For class schedule (Phase 3) — from starter kit schema
CREATE TABLE IF NOT EXISTS class_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id uuid REFERENCES gyms(id) ON DELETE CASCADE,
  title text NOT NULL,
  coach_id uuid REFERENCES users(id),
  day_of_week int NOT NULL, -- 0=Mon...6=Sun
  start_time time NOT NULL,
  duration_mins int DEFAULT 60,
  max_capacity int DEFAULT 20,
  location text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS class_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid REFERENCES class_schedules(id) ON DELETE CASCADE,
  member_id uuid REFERENCES users(id) ON DELETE CASCADE,
  booked_at timestamptz DEFAULT now(),
  status text DEFAULT 'booked', -- booked | cancelled | attended
  UNIQUE(schedule_id, member_id)
);
```

---

## Deployment Plan

### Mobile App
- iOS: App Store via Xcode archive + `flutter build ipa`
- Android: Play Store via `flutter build appbundle`
- TestFlight / internal testing first

### Backend (NestJS)
- **Recommended:** Railway or Render (free tier for dev, $5-7/month for production)
- Docker image: `nest build` → Dockerfile → Railway deploy
- Environment: set all `.env` vars in Railway dashboard
- Database: switch `DATABASE_URL` from local to Supabase pooler URL

### Admin Portal (Next.js)
- **Recommended:** Vercel (Next.js is made by Vercel, zero-config deployment)
- Connect GitHub repo → auto-deploy on push to `main`
- Set env vars in Vercel dashboard
- Custom domain: `admin.pulse-gym.app` or similar

### Supabase Edge Functions
- Already deployed via `supabase functions deploy`
- No additional hosting needed

---

## Security Checklist

Before production launch:

- [ ] `SUPABASE_SERVICE_ROLE_KEY` never in client code (Flutter or admin portal browser JS)
- [ ] `SKIP_LOGIN_FOR_TESTING = false` in Flutter
- [ ] RLS migration 008 applied to Supabase
- [ ] Supabase JWT secret in NestJS `.env` matches project JWT settings
- [ ] Stripe webhook secret set and verified
- [ ] `SUPABASE_JWT_SECRET` rotated from default (already done — using UUID)
- [ ] Admin portal behind HTTPS (Vercel handles this automatically)
- [ ] Rate limiting on `/auth/request-otp` (currently handled by Supabase Auth natively)
- [ ] Error messages don't leak user existence (`Not registered` vs `Invalid OTP`)

---

## OTP Fix (Immediate)

Supabase is sending magic links instead of 6-digit codes. Fix:

**Supabase Dashboard → Authentication → Providers → Email:**
- Enable email confirmations: **OFF**
- Use OTP for magic links: depends on Supabase version

**Alternative — call with explicit OTP options:**
The `signInWithOtp` call in `auth-request-otp/index.ts` can be modified:

```typescript
// Force OTP mode explicitly
const { error } = await admin.auth.signInWithOtp({
  email,
  options: {
    shouldCreateUser: false,
    emailRedirectTo: undefined, // prevents magic link, forces OTP code
    data: { gym_id, roster_id: roster.id, gym_name: gym.name }
  }
})
```

Or switch to **phone OTP** (SMS via Twilio) which always sends a numeric code.
See `supabase/config.toml` `[auth.sms.twilio]` section for Twilio setup.
