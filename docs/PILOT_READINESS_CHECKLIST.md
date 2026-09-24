# Pilot Readiness Checklist

Use this before handing Tether to a real gym for internal pilot testing.

## 1. Environment Setup

### Backend
- Confirm `gym-app-backend/.env` points at the intended Supabase project.
- Set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`, and `DATABASE_URL`.
- Run the backend locally on `PORT=3001` when using `tether-web` locally.

### Staff portal
- In `tether-web/.env.local`, set:

```env
NEXT_PUBLIC_API_URL=http://localhost:3001
```

- Run `npm install` in `tether-web` after dependency changes.

### Mobile app
- The app defaults to `http://10.0.2.2:3001` (Android emulator only). Physical phones need the LAN IP, and release builds refuse to start without it:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3001
```

## 2. Database And Auth

- Apply Prisma and Supabase SQL migrations.
- Ensure at least one `gyms` row exists.
- Ensure at least one admin staff account exists for the target gym.
- Confirm the staff account can log in through `/login`.
- Confirm at least one member account exists and belongs to the same gym.

## 3. Portal Smoke Test

- `/login` works with the staff account.
- `/dashboard` loads live stats.
- `/dashboard/members` lists gym members.
- `/dashboard/members/[memberId]` loads and allows member edits.
- `/dashboard/roster` supports add, import, and approve.
- `/dashboard/notices` supports create, edit, delete, and restore.
- `/dashboard/feed` shows flagged items and moderation actions.
- `/dashboard/settings` supports gym settings edits and staff account management.

## 4. Mobile App Smoke Test

- Member auth flow works from gym selection through login.
- Home loads live notices and does not show fake social counts.
- Social feed loads, likes work, comments work, and flagging removes flagged posts locally.
- Workout session start/resume/end flow works.
- Workout sharing posts correctly to the gym feed.
- Coach certification works from a coach account.
- Notices screen loads live notices from the backend.

## 5. Security / Safety Checks

- Staff routes are gym-scoped and reject cross-gym access.
- Member data is not exposed across gyms.
- Destructive actions are limited to staff-authenticated routes.
- Supabase storage access is limited to intended buckets and signed URLs where needed.
- Reset-password and invite flows are tested with real email delivery.

## 6. Deployment Checklist

- Backend deploy target has the same env vars as local.
- Web deploy target uses the correct API base URL (`NEXT_PUBLIC_API_URL`).
- Supabase project URLs, JWT config, and email templates are finalized.
- Seed or onboarding steps are documented for first gym setup.
- One shared support note exists for common failures: wrong port, wrong API URL, missing gym row, missing staff row, expired token.
- See `docs/OPS_RUNBOOK.md` for local ports, Flutter LAN URL, and production packaging notes.
