# Setup Guide

## Prerequisites

- Flutter SDK 3.12+ (`flutter doctor` to verify)
- Node.js 18+ (for admin portal)
- Supabase CLI (`npm install -g supabase`)
- A Supabase project (create at https://supabase.com)
- Twilio account (for SMS OTP)
- Stripe account (for billing)

## Step 1: Supabase Project Setup

### 1.1 Create Project
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose organization, name it `gym-saas-prod`
4. Save the **Project URL** and **anon public** key from Settings > API

### 1.2 Enable Phone Auth
1. Go to **Authentication > Providers > Phone**
2. Toggle **Enabled**
3. Select **Twilio** as provider
4. Enter:
   - Twilio Account SID
   - Twilio Auth Token
   - Twilio Verify Service SID
5. Save

### 1.3 Configure Auth URLs
1. Go to **Authentication > URL Configuration**
2. Set **Site URL**: `io.supabase.gymapp://login-callback/`
3. Add to **Redirect URLs**:
   - `io.supabase.gymapp://login-callback/`
   - `http://localhost:3000/**` (for admin portal dev)

## Step 2: Database Setup

### 2.1 Link Local Project
```bash
cd supabase/
supabase login
supabase link --project-ref <your-project-ref>
```

### 2.2 Push Migrations
```bash
supabase db push
```

This creates all tables, indexes, RLS policies, and triggers.

### 2.3 Verify Setup
Open the SQL Editor in Supabase Dashboard and run:
```sql
select * from public.gyms; -- Should be empty
\d public.gym_members      -- Should show table structure
```

## Step 3: Deploy Edge Functions

```bash
supabase functions deploy auth-request-otp
supabase functions deploy auth-verify-otp
supabase functions deploy admin-import-members
supabase functions deploy push-notify
```

### Set Function Secrets (if needed)
```bash
# Only needed if functions need external API keys
supabase secrets set FCM_SERVER_KEY=your-fcm-key
```

## Step 4: Flutter App Setup

### 4.1 Install Dependencies
```bash
cd flutter/
flutter pub get
```

### 4.2 Generate Freezed Models
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4.3 Configure Environment

**Option A: Command line**
```bash
flutter run --dart-define=SUPABASE_URL=https://yourproject.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**Option B: VS Code launch.json**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "gym_app_mobile",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define", "SUPABASE_URL=https://yourproject.supabase.co",
        "--dart-define", "SUPABASE_ANON_KEY=your-anon-key"
      ]
    }
  ]
}
```

**Option C: Android Studio / IntelliJ**
Add to **Run > Edit Configurations > Additional run args**:
```
--dart-define=SUPABASE_URL=https://yourproject.supabase.co
--dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 4.4 Run the App
```bash
flutter run
```

## Step 5: Create Your First Gym

### 5.1 Insert Gym Record
Open Supabase SQL Editor:
```sql
insert into public.gyms (
  name, slug, code, admin_email, subscription_status, plan_tier
) values (
  'Iron Pump Gym',
  'iron-pump',
  'IRON2024',
  'admin@ironpump.com',
  'active',
  'standard'
);
```

Note the returned `id` (UUID).

### 5.2 Add Staff Member (for admin portal)

1. Go to Supabase Dashboard > Authentication > Users
2. Click "Add User" → enter email + password
3. Note the UUID of the created user
4. Run in SQL Editor:
```sql
insert into public.gym_staff (
  gym_id, auth_user_id, email, full_name, role
) values (
  '<gym-uuid-from-step-5.1>',
  '<auth-user-uuid>',
  'admin@ironpump.com',
  'Gym Owner',
  'owner'
);
```

### 5.3 Pre-register Members
```sql
insert into public.gym_members (
  gym_id, email, full_name, role
) values
  ('<gym-uuid>', 'john@example.com', 'John Doe', 'member'),
  ('<gym-uuid>', 'jane@example.com', 'Jane Smith', 'coach'),
  ('<gym-uuid>', 'mike@example.com', 'Mike Johnson', 'member');
```

## Step 6: Test the Auth Flow

1. Open the Flutter app
2. Search for "Iron Pump" or enter code `IRON2024`
3. Select the gym
4. Enter `john@example.com`
5. Check email for OTP (or Twilio logs for SMS)
6. Enter OTP
7. You should be logged in and see the main navigation

## Step 7: Admin Portal Setup

```bash
cd admin-web/
npm install
```

Create `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://yourproject.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

Run dev server:
```bash
npm run dev
```

Open http://localhost:3000 and log in with the staff email/password from Step 5.2.

## Step 8: Stripe Billing (Optional but Recommended)

### 8.1 Create Stripe Products
In Stripe Dashboard:
1. Create Product: "Gym SaaS - Basic" → Price: $49/month
2. Create Product: "Gym SaaS - Standard" → Price: $99/month
3. Create Product: "Gym SaaS - Premium" → Price: $199/month

Note the Price IDs (they look like `price_1ABC...`).

### 8.2 Configure Webhook
1. In Stripe Dashboard > Developers > Webhooks
2. Add endpoint: `https://yourproject.supabase.co/functions/v1/stripe-webhook`
3. Select events:
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `customer.subscription.deleted`

### 8.3 Add Stripe Keys
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

### 8.4 Deploy Stripe Webhook Function
Create `supabase/functions/stripe-webhook/index.ts` (see ADMIN_PORTAL_GUIDE.md).

## Troubleshooting

### "Failed to send OTP" Error
- Check Twilio credentials in Supabase Dashboard
- Verify the phone number is in E.164 format (+1234567890)
- Check Edge Function logs: `supabase functions logs auth-request-otp`

### "Not registered with this gym" Error
- Verify `gym_members` row exists with matching email/phone and `gym_id`
- Check `is_active` is `true`
- Check gym `subscription_status` is `active` or `trialing`

### RLS Errors ("new row violates row-level security policy")
- Verify JWT contains `gym_id` claim: decode at https://jwt.io
- Check `auth.users.raw_user_meta_data` has `gym_id` and `member_id`
- Ensure `gym_members.auth_user_id` is linked

### Flutter Build Errors
- Run `flutter clean && flutter pub get`
- Run `dart run build_runner build --delete-conflicting-outputs`
- Ensure `AppConstants.supabaseUrl` and `supabaseAnonKey` are not empty
