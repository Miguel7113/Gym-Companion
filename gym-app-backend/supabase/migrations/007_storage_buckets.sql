-- =============================================================================
-- Migration 006: Storage Buckets
-- Run this in the Supabase SQL editor (uses the storage schema)
-- Alternatively create these via Supabase Dashboard → Storage → New Bucket
-- =============================================================================

-- Avatars bucket — user profile pictures
-- Authenticated users can upload their own; public read for display
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880,   -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Gym assets bucket — logos, banners uploaded by gym staff
-- Public read so the app can display gym logos without auth
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'gym-assets',
    'gym-assets',
    true,
    10485760,  -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- Post images bucket — photos attached to social feed posts
-- Public read; authenticated users can upload
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post-images',
    'post-images',
    true,
    10485760,  -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Import files bucket — CSV / Apple Health XML uploads (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'import-files',
    'import-files',
    false,
    52428800,  -- 50MB limit (Apple Health exports can be large)
    ARRAY['text/csv', 'application/xml', 'text/xml', 'application/zip']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- Storage RLS Policies
-- =============================================================================

-- avatars: authenticated users can upload to their own folder (userId/filename)
CREATE POLICY "avatars_upload_own"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_update_own"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- gym-assets: public read; only service role can write (backend handles uploads)
CREATE POLICY "gym_assets_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'gym-assets');

-- post-images: authenticated users can upload; public read
CREATE POLICY "post_images_upload_authenticated"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'post-images' AND
        auth.role() = 'authenticated'
    );

CREATE POLICY "post_images_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'post-images');

-- import-files: users can only access their own uploads
CREATE POLICY "import_files_upload_own"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'import-files' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "import_files_read_own"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'import-files' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );
