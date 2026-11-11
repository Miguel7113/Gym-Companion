-- =============================================================================
-- Migration 016: Allow staff to upload gym assets (logos)
-- =============================================================================
-- Extends the gym-assets bucket RLS to allow authenticated staff members
-- to upload, update, and delete files in their gym's folder.
--
-- Path structure: gym-assets/{gymId}/logo.{ext}
-- =============================================================================

-- Allow authenticated staff to upload gym assets to their own gym's folder
CREATE POLICY "gym_assets_staff_upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'gym-assets' AND
        -- Staff can only upload to their own gym's folder
        (storage.foldername(name))[1] IN (
            SELECT gym_id::text FROM public.gym_staff 
            WHERE auth_provider_id = auth.uid()::text
        )
    );

-- Allow authenticated staff to update (replace) existing files in their gym's folder
CREATE POLICY "gym_assets_staff_update"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'gym-assets' AND
        (storage.foldername(name))[1] IN (
            SELECT gym_id::text FROM public.gym_staff 
            WHERE auth_provider_id = auth.uid()::text
        )
    );

-- Allow authenticated staff to delete files in their gym's folder
CREATE POLICY "gym_assets_staff_delete"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'gym-assets' AND
        (storage.foldername(name))[1] IN (
            SELECT gym_id::text FROM public.gym_staff 
            WHERE auth_provider_id = auth.uid()::text
        )
    );

-- Note: Public read policy already exists from migration 007
