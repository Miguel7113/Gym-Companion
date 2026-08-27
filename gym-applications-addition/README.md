# Gym Applications — Apply-to-Join Flow

Replaces the fully-open `/staff-auth/signup` design from before. Now:

1. Gym fills out a public form on the marketing site → `POST /gym-applications` (no auth) — just stores a lead, creates no account
2. You review pending applications: `GET /gym-applications/pending` with header `X-Admin-Key: <your SUPER_ADMIN_KEY>`
3. You approve a real prospect: `POST /gym-applications/:id/approve` (same header) — THIS is what actually creates the `Gym` + first `GymStaff` row and sends them an OTP
4. The gym owner goes to `/login` on the website, enters their email, gets an OTP (their `gym_staff` row now exists so the existing login flow just works), completes login into their new dashboard

## Setup
1. Add the `GymApplication` model from `schema-addition.prisma` to your existing `prisma/schema.prisma`
2. `npm run prisma:generate && npm run prisma:migrate`
3. Drop in `src/gym-applications/` as-is
4. Add `GymApplicationsModule` to `app.module.ts`'s imports
5. Set `SUPER_ADMIN_KEY` in your backend's `.env` — a long random string, this is the only thing gating who can approve applications, so treat it like a password
6. You can either build a tiny internal review page later, or just use `curl`/Postman with the `X-Admin-Key` header while application volume is low — genuinely fine to do it this way until reviewing applications becomes frequent enough to be annoying

## Remove the earlier open signup
If you already merged `/staff-auth/signup` from the previous round, either delete that route entirely or leave it in but don't link to it publicly — `gym-applications` is the new front door.
