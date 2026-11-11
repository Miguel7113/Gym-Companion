# Gym Onboarding - Quick Reference

**One-page cheat sheet for onboarding a new gym.**

---

## Before You Start

Collect from the gym:
- Name, admin email, timezone, color (hex), logo file
- Member roster CSV: `email,memberName,phone`

---

## 1. Create Gym (5 min)

```bash
cd gym-app-backend

npm run gym:create -- \
  --name "Gym Name" \
  --admin-email admin@gym.com \
  --timezone "Africa/Nairobi" \
  --color "#FF6B35"
```

**Save the auto-generated password!**

---

## 2. Send Welcome Email (template)

```
Subject: GymPulse Portal Access

Portal: https://portal.gympulse.app/login
Email: [their-email]
Password: [generated-password]

Next: Upload roster, add coaches, done!
```

---

## 3. Test Member Flow

1. Member downloads app → selects gym → enters roster email → OTP → logs in ✅
2. Verify in portal: Members → should show as "matched"

---

## Common Timezone Values

- **East Africa:** `Africa/Nairobi`
- **UK:** `Europe/London`
- **US East:** `America/New_York`
- **US West:** `America/Los_Angeles`
- **Australia:** `Australia/Sydney`

Full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| "Email already exists" | Use different email or delete old auth user |
| Gym not in app | Check `is_active = true` in database |
| Member can't sign up | Verify exact email/phone match in roster |

---

## SQL Quick Checks

```sql
-- List all gyms
SELECT id, name, is_active, created_at FROM gyms ORDER BY created_at DESC;

-- Check roster for a gym
SELECT email, member_name, status FROM gym_roster WHERE gym_id = 'xxx';

-- Make gym active
UPDATE gyms SET is_active = true WHERE id = 'xxx';
```

---

## Script Flags Reference

```bash
npm run gym:create -- \
  --name "Required: Gym display name" \
  --admin-email "Required: Portal admin email" \
  --timezone "Optional: Default UTC" \
  --color "Optional: #RRGGBB hex" \
  --admin-password "Optional: Auto-generated if omitted" \
  --contact-email "Optional: Public contact" \
  --logo-url "Optional: Direct URL to logo"
```

---

**Total Time:** 15-30 minutes per gym  
**Full Guide:** `docs/GYM_ONBOARDING_CHECKLIST.md`
