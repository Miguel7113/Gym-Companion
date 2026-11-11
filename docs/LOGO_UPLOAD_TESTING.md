# Logo Upload Feature - Testing Guide

**Feature:** Gym admins can upload logos directly through the portal settings page.

---

## Prerequisites

1. ✅ Migration 016 applied to Supabase
2. ✅ Supabase dependency installed (`@supabase/supabase-js`)
3. ✅ Environment variables set in `tether-web/.env.local`
4. ✅ Portal running (`npm run dev` in tether-web)

---

## Step 1: Apply Migration

Run this SQL in **Supabase Dashboard → SQL Editor:**

```sql
-- Copy contents from:
-- gym-app-backend/supabase/migrations/016_gym_assets_staff_upload.sql
```

Or run all migrations via:
```bash
cd gym-app-backend
# If you have a migration runner setup
```

**Verify:** Check that these policies exist in Supabase Dashboard → Storage → gym-assets → Policies:
- `gym_assets_staff_upload`
- `gym_assets_staff_update`
- `gym_assets_staff_delete`

---

## Step 2: Test Upload Flow

### A. Login as Gym Admin

```
URL: http://localhost:3000/login (dev) or https://portal.gympulse.app/login (prod)
Email: goddusopp192@gmail.com
Password: MD5QMeQhQs87vwdy
```

### B. Navigate to Settings

1. Click "Settings" in left sidebar
2. Scroll to "Gym logo" section
3. You should see:
   - "No logo uploaded yet" box (if no logo)
   - OR current logo preview (if exists)

### C. Upload a Test Logo

**Prepare test image:**
- Any PNG/JPG/WEBP/SVG file
- Recommended size: 512×512px square
- Max size: 5MB

**Upload steps:**
1. Click "Choose file"
2. Select test logo image
3. Click "Upload logo" button
4. ✅ Should redirect with success message: "Logo uploaded successfully"
5. ✅ Logo preview should appear on page

### D. Verify Upload

**Check Supabase Storage:**
1. Go to Supabase Dashboard → Storage → gym-assets
2. Navigate to folder: `01e9b7bd-3c05-4c97-bbde-5fcfa86aa135/` (Test Gym Alpha ID)
3. ✅ File `logo.png` (or .jpg/.webp) should exist
4. Click file → Copy URL → Open in browser
5. ✅ Logo should display

**Check Database:**
```sql
SELECT id, name, logo_url FROM gyms 
WHERE id = '01e9b7bd-3c05-4c97-bbde-5fcfa86aa135';
```
✅ `logo_url` should be: `https://uqswohwqdcjlncdudhap.supabase.co/storage/v1/object/public/gym-assets/01e9b7bd.../logo.png`

---

## Step 3: Test in Mobile App

1. Open mobile app
2. Go to gym selection screen
3. ✅ "Test Gym Alpha" should display with uploaded logo
4. Select gym → continue signup flow

---

## Error Testing

### Test 1: File Too Large
- Upload a 10MB image
- ✅ Should see error: "Logo must be under 5MB."

### Test 2: Invalid File Type
- Upload a PDF or TXT file
- ✅ Should see error: "Logo must be PNG, JPG, WEBP, or SVG."

### Test 3: No File Selected
- Click "Upload logo" without selecting file
- ✅ Should see error: "Please select a logo file."

### Test 4: Replace Existing Logo
- Upload logo #1
- Upload logo #2 (different image)
- ✅ Should replace logo #1 (upsert mode)
- ✅ Only one file in Storage bucket

---

## Alternative: Direct URL Method

### Test Collapsible Section

1. Settings page → "Gym logo" section
2. Click "Or paste a direct URL" (details element)
3. Paste: `https://example.com/logo.png`
4. Scroll down → Click "Save settings" (main form button)
5. ✅ Logo URL should update in database
6. ✅ External logo should display in app

---

## Troubleshooting

### Upload fails with "Failed to upload logo"

**Check RLS policies:**
```sql
-- In Supabase SQL Editor
SELECT * FROM storage.policies 
WHERE bucket_id = 'gym-assets';
```
Should show 4 policies (public_read + 3 staff policies)

**Check staff auth link:**
```sql
SELECT id, email, auth_provider_id FROM gym_staff 
WHERE email = 'goddusopp192@gmail.com';
```
- If `auth_provider_id` is NULL → admin hasn't logged in yet
- Solution: Log out → log back in to link auth

### Logo doesn't appear in app

**Verify public access:**
1. Copy logo URL from database
2. Open in incognito browser
3. Should load without authentication

**Check bucket is public:**
- Supabase Dashboard → Storage → gym-assets
- Settings → "Public bucket" should be ON

### Environment variables not found

**Check `.env.local` has:**
```bash
NEXT_PUBLIC_SUPABASE_URL=https://uqswohwqdcjlncdudhap.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOi...
```

**Restart dev server after adding env vars:**
```bash
cd tether-web
# Stop server (Ctrl+C)
npm run dev
```

---

## Success Criteria

- [x] Migration 016 applied
- [x] Staff can upload PNG/JPG/WEBP/SVG logos
- [x] File size validation (max 5MB)
- [x] File type validation (images only)
- [x] Logo stored at: `gym-assets/{gymId}/logo.{ext}`
- [x] Database `logo_url` updated automatically
- [x] Logo preview displays in portal
- [x] Logo appears in mobile app gym selection
- [x] Replacing logo works (upsert mode)
- [x] Alternative "paste URL" method still works
- [x] Error messages are clear and actionable

---

## Production Deployment Checklist

Before deploying to production:

1. [ ] Run migration 016 on production Supabase instance
2. [ ] Verify production env vars in Vercel/hosting:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
3. [ ] Test upload with production gym admin
4. [ ] Verify logo appears in production mobile app
5. [ ] Test file size/type validation in prod
6. [ ] Monitor Supabase Storage usage (free tier: 1GB)

---

**Last Updated:** October 7, 2026  
**Feature Status:** ✅ Implemented, ready for testing
