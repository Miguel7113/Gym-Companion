# Connecting Supabase to the Project

This guide walks through everything needed to wire up your Supabase project to the backend.

---

## What Supabase Provides

This project uses Supabase for two separate things:

1. **Auth** — OTP (email/SMS) for members, email+password for staff. Supabase manages user sessions and issues JWTs.
2. **PostgreSQL Database** — The Prisma ORM connects directly to the Supabase-hosted Postgres instance.

---

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New project**.
3. Give it a name (e.g. `gym-app`), set a strong database password, and choose a region close to your users.
4. Wait for the project to finish provisioning (about 1–2 minutes).

---

## Step 2: Gather Your Credentials

You need four values from your Supabase dashboard. All of them live under **Project Settings → API**.

| Value | Where to find it | Maps to env var |
|-------|-----------------|-----------------|
| Project URL | Settings → API → Project URL | `SUPABASE_URL` |
| `service_role` key | Settings → API → Project API keys → `service_role` | `SUPABASE_SERVICE_ROLE_KEY` |
| JWT Secret | Settings → API → JWT Settings → JWT Secret | `SUPABASE_JWT_SECRET` |
| Database connection string | Settings → Database → Connection string → URI | `DATABASE_URL` |

> **Important:** The `service_role` key has admin privileges and bypasses Row Level Security. Keep it server-side only — never expose it in the mobile app or frontend.

---

## Step 3: Configure Your .env File

Copy the example file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# Your Supabase Postgres connection string
# Found in: Project Settings → Database → Connection string → URI
# Replace [YOUR-PASSWORD] with the database password you set when creating the project
DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Your Supabase project URL
# Found in: Project Settings → API → Project URL
SUPABASE_URL="https://[YOUR-PROJECT-REF].supabase.co"

# Service role key (admin-level, server-side only)
# Found in: Project Settings → API → service_role
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# JWT Secret (used by guards to verify tokens)
# Found in: Project Settings → API → JWT Settings → JWT Secret
SUPABASE_JWT_SECRET="your-super-secret-jwt-token-with-at-least-32-characters"

PORT=3000
```

---

## Step 4: Enable OTP Providers in Supabase

### Email OTP (required for member sign-up via email)

1. Go to **Authentication → Providers**.
2. **Email** is enabled by default. No extra steps needed.
3. Optionally, go to **Authentication → Email Templates** to customise the OTP email.

### Phone/SMS OTP (if using phone-based sign-up)

1. Go to **Authentication → Providers → Phone**.
2. Enable it and choose your SMS provider (Twilio is the most common).
3. Enter your Twilio Account SID, Auth Token, and phone number.
4. Set **OTP expiry** to your preference (default 60 seconds is fine for testing).

> If you only plan to use email OTP during development, you can skip phone setup for now.

---

## Step 5: Configure Auth Settings

In the Supabase dashboard under **Authentication → Configuration → Auth**:

- **Disable email confirmation** (for OTP flow, the OTP itself is the confirmation — no separate email link needed).
  - Set **"Enable email confirmations"** to **OFF**.
- Set OTP expiry to `3600` (1 hour) or lower based on your UX preference.

---

## Step 6: Run the Database Migration

Once your `.env` is set up, push the Prisma schema to your Supabase database:

```bash
cd gym-app-backend
npm install
npm run prisma:migrate
```

This creates all the tables defined in `prisma/schema.prisma`.

Then seed the database with a pilot gym, local foods, and exercises:

```bash
npm run prisma:seed
```

---

## Step 7: Verify the Connection

Start the dev server:

```bash
npm run start:dev
```

Test a public endpoint to confirm the DB connection:

```bash
curl http://localhost:3000/gyms
```

You should get back a JSON array (empty if no gyms seeded yet, or with the pilot gym if you ran the seed).

---

## Step 8: Test Auth End-to-End

### Add a test member to the roster

```bash
curl -X POST http://localhost:3000/auth/staff/login \
  -H "Content-Type: application/json" \
  -d '{ "email": "staff@yourgym.com", "password": "yourpassword" }'
```

Use the returned `accessToken` to call a staff endpoint and add a roster entry:

```bash
curl -X POST http://localhost:3000/roster/entry \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{ "gymId": "<your-gym-id>", "email": "member@example.com" }'
```

### Request OTP for the member

```bash
curl -X POST http://localhost:3000/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{ "gymId": "<your-gym-id>", "email": "member@example.com" }'
```

Check your email for the OTP, then verify it:

```bash
curl -X POST http://localhost:3000/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{ "gymId": "<your-gym-id>", "email": "member@example.com", "token": "123456" }'
```

A successful response contains `accessToken` and `refreshToken`. The member is now signed up.

---

## Troubleshooting

**`Error: invalid JWT secret`** — Double-check `SUPABASE_JWT_SECRET` in `.env`. Copy it exactly from Supabase Dashboard → Settings → API → JWT Settings.

**`P1001: Can't reach database server`** — Check `DATABASE_URL`. Make sure you replaced `[YOUR-PASSWORD]` with your actual DB password.

**`AuthApiError: Email signups are disabled`** — Go to Authentication → Providers → Email and make sure the Email provider is enabled.

**`UnauthorizedException: User account not found`** — The JWT is valid but the user doesn't exist in the `users` table. This usually means `verify-otp` wasn't called first (the signup step). Run the full OTP flow to create the user row.

**OTP not arriving** — Check your Supabase project's Auth logs under **Authentication → Logs**. For local/dev testing, Supabase provides an email testing interface at `https://supabase.com/dashboard/project/<id>/auth/users`.
