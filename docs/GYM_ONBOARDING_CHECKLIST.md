# Gym Onboarding Checklist

**Purpose:** Step-by-step guide to onboard a new gym to GymPulse/Tether platform.

---

## Pre-Onboarding (Sales/Discovery)

Before running the script, collect this information from the gym:

- [ ] **Gym Name** - Official business name
- [ ] **Primary Contact Email** - For portal admin account
- [ ] **Contact Phone** - For support
- [ ] **Timezone** - City format (e.g., `Africa/Nairobi`, `America/New_York`, `Europe/London`)
- [ ] **Brand Color** (optional) - Hex code (e.g., `#FF6B35`)
- [ ] **Logo File** (optional) - Square PNG/JPG, min 512×512px
- [ ] **Member Roster** - CSV with columns: `email`, `memberName`, `phone` (optional)

**Timezone Reference:** https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

---

## Step 1: Create Gym & Admin Account (5 min)

Run the CLI script from the backend directory:

```bash
cd gym-app-backend

npm run gym:create -- \
  --name "Gym Name Here" \
  --admin-email admin@theirgym.com \
  --timezone "Africa/Nairobi" \
  --color "#FF6B35" \
  --contact-email info@theirgym.com
```

**Script will output:**
- Gym ID (UUID)
- Admin email
- **Auto-generated password** ⚠️ SAVE THIS - show it to gym admin only once

**Optional flags:**
- `--admin-password "CustomPass123!"` - Set custom password instead of auto-generated
- `--logo-url "https://..."` - Direct URL to logo (portal upload is easier)
- `--contact-email "info@gym.com"` - Public contact email

### What the script does:
1. Creates gym record in `gyms` table
2. Creates Supabase auth user for admin
3. Creates staff record in `gym_staff` table
4. Links admin to gym via `gymId` foreign key

---

## Step 2: Send Welcome Email to Gym Admin (2 min)

**Template:**

```
Subject: Welcome to GymPulse - Your Portal Access

Hi [Admin Name],

Your gym "[Gym Name]" is now live on GymPulse!

Portal Login:
→ https://portal.gympulse.app/login

Email: [admin@theirgym.com]
Password: [MD5QMeQhQs87vwdy]  ⚠️ Please change this on first login

Next Steps:
1. Log in to the portal
2. Upload your member roster (Settings → Roster)
3. Invite your coaches (Settings → Staff)
4. Your members can now download the app and select your gym!

Questions? Reply to this email or call [support number].

Welcome aboard!
- The GymPulse Team
```

---

## Step 3: Guide Admin Through First Login (10 min)

Walk them through or send instructions:

### A. Portal Login
1. Go to https://portal.gympulse.app/login
2. Enter email + generated password
3. Change password (force this on first login)
4. **(Optional but Recommended)** Upload gym logo:
   - Settings → Gym profile → "Gym logo" section
   - Click "Choose file" → select logo (PNG/JPG/SVG)
   - Click "Upload logo"
   - Logo will appear in app gym selection screen

### B. Upload Member Roster
1. Navigate to **Settings → Roster**
2. Click **Upload CSV**
3. Required format:
   ```csv
   email,memberName,phone
   john@example.com,John Smith,+254712345678
   jane@example.com,Jane Doe,+254723456789
   ```
4. Review preview
5. Click **Import**

**Roster rules:**
- Email OR phone required (at least one)
- System will match members when they sign up in the app
- Status starts as `unmatched`, becomes `matched` when user signs up

### C. Add Coaches (optional)
1. Navigate to **Settings → Staff**
2. Click **Add Staff**
3. Enter email, select role: `coach`
4. Coach receives invite email

---

## Step 4: Test Member Signup Flow (5 min)

Use a test member from the roster:

1. **Mobile App:**
   - Download GymPulse app (iOS/Android)
   - Tap "Get Started"
   - Select "[Gym Name]" from list
   - Enter email/phone from roster
   - Request OTP
   - Verify code
   - Set password
   - ✅ Should see home screen

2. **Verify in Portal:**
   - Admin logs into portal
   - Navigate to Members
   - Test member should show as `matched`

---

## Step 5: Configure Gym Settings (optional, 5 min)

Help admin customize:

### A. Branding
- Settings → Gym profile
  - **Upload logo** via file picker (recommended) OR paste URL
  - Set primary color (hex code)
  - Changes appear immediately in app

### B. Notifications
- Settings → Notifications
  - Enable/disable auto-posts for PRs
  - Configure streak reminders

### C. Gym Info
- Settings → Details
  - Add gym address
  - Set opening hours
  - Add facility amenities

---

## Step 6: Monitor First Week (ongoing)

**Day 1-3:**
- [ ] Check roster match rate (target: >80%)
- [ ] Verify coaches can create workouts
- [ ] Monitor error logs for this gym

**Day 7:**
- [ ] Check in with admin via email
- [ ] Review member engagement (active users %)
- [ ] Collect feedback

---

## Troubleshooting

### Script fails with "Email already exists"
**Cause:** Admin email already registered in Supabase Auth  
**Fix:** Use a different email or delete the existing auth user via Supabase Dashboard

### Members can't find gym in app
**Cause:** Gym `is_active` set to false  
**Fix:** 
```sql
UPDATE gyms SET is_active = true WHERE id = 'gym-id-here';
```

### Roster upload fails
**Cause:** CSV format incorrect or duplicate emails  
**Fix:** 
- Ensure CSV has headers: `email,memberName,phone`
- Remove duplicate rows
- Check for special characters in names

### Member sees "Not on roster" error
**Cause:** Email/phone doesn't match roster exactly  
**Fix:**
- Check for typos (spaces, case sensitivity)
- Add member manually via portal: Members → Add Member

---

## Post-Onboarding Checklist

- [ ] Gym created and active in database
- [ ] Admin has portal access and changed password
- [ ] **Logo uploaded** (via portal or URL)
- [ ] Roster uploaded (min 5 members)
- [ ] At least 1 coach added
- [ ] Test member successfully signed up via app
- [ ] Admin trained on basic portal navigation
- [ ] Support contact info shared
- [ ] Gym added to internal tracking spreadsheet

---

## Internal Tracking

Add new gym to **Gyms Tracker** (spreadsheet/Notion):

| Gym ID | Name | Onboarded Date | Admin Email | Member Count | Status | Notes |
|--------|------|----------------|-------------|--------------|--------|-------|
| 01e9b... | Test Gym Alpha | 2026-10-07 | admin@... | 0 | Active | Test gym |

---

## Scripts Reference

### Create gym
```bash
npm run gym:create -- --name "Name" --admin-email email@gym.com --timezone "Africa/Nairobi"
```

### Delete test gym (dev only)
```sql
-- Run in Supabase SQL Editor
DELETE FROM gyms WHERE id = 'gym-id-here';
-- Note: Cascades to staff, roster, sessions, posts
```

### List all gyms
```sql
SELECT id, name, is_active, created_at 
FROM gyms 
ORDER BY created_at DESC;
```

### Check gym stats
```bash
curl https://api.gympulse.app/gyms/{gym-id}/stats \
  -H "Authorization: Bearer {staff-token}"
```

---

## Timeline Summary

| Task | Time | Owner |
|------|------|-------|
| Pre-onboarding data collection | 10 min | Sales |
| Run creation script | 5 min | Eng/Ops |
| Send welcome email | 2 min | Eng/Ops |
| Admin first login + setup | 15 min | Gym Admin (guided) |
| Test member flow | 5 min | Eng/Ops |
| Total | ~37 min | |

**Target:** Under 30 minutes hands-on time per gym (for you)

---

## Next Steps After Phase 1

When you hit **10-15 gyms**, consider building:
- **Super-admin web UI** for non-technical staff to onboard gyms
- **Self-service signup** with Stripe integration
- **Automated welcome emails** (via Resend/SendGrid)

For now, this manual process scales to ~50 gyms comfortably.

---

**Last Updated:** October 7, 2026  
**Maintained By:** Engineering Team
