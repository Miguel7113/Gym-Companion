-- Workout photos are private. The API stores the object path and returns a
-- short-lived signed URL after applying gym-scoped feed authorization.

-- Keep this migration safe to run on projects where migration 008 has not
-- been applied yet. CREATE OR REPLACE is harmless when these helpers already
-- exist.
create or replace function public.get_my_gym_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'gym_id'),
    ''
  )::uuid;
$$;

create or replace function public.get_my_member_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'member_id'),
    ''
  )::uuid;
$$;

create or replace function public.get_my_role()
returns text
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'role'),
    ''
  )::text;
$$;

-- This link was added in the backend Prisma migration, but Supabase projects
-- may use the SQL migrations independently.
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS workout_session_id text;

CREATE UNIQUE INDEX IF NOT EXISTS posts_workout_session_id_key
  ON public.posts(workout_session_id)
  WHERE workout_session_id IS NOT NULL;

DO $$
BEGIN
  IF to_regclass('public.workout_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1
       FROM pg_constraint
       WHERE conname = 'posts_workout_session_id_fkey'
     ) THEN
    ALTER TABLE public.posts
      ADD CONSTRAINT posts_workout_session_id_fkey
      FOREIGN KEY (workout_session_id)
      REFERENCES public.workout_sessions(id)
      ON DELETE SET NULL
      ON UPDATE CASCADE;
  END IF;
END
$$;

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS image_path text;

UPDATE storage.buckets
SET public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id = 'post-images';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "post_images_upload_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "post_images_public_read" ON storage.objects;
DROP POLICY IF EXISTS "post_images_upload_own" ON storage.objects;
DROP POLICY IF EXISTS "post_images_update_own" ON storage.objects;
DROP POLICY IF EXISTS "post_images_delete_own" ON storage.objects;

CREATE POLICY "post_images_upload_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'post-images'
    AND auth.role() = 'authenticated'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "post_images_update_own"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "post_images_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE TABLE IF NOT EXISTS public.coach_certifications (
  id text PRIMARY KEY,
  post_id text NOT NULL UNIQUE REFERENCES public.posts(id) ON DELETE CASCADE,
  coach_user_id text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gym_id text NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS coach_certifications_gym_id_idx
  ON public.coach_certifications(gym_id);

CREATE INDEX IF NOT EXISTS coach_certifications_coach_user_id_idx
  ON public.coach_certifications(coach_user_id);

ALTER TABLE public.coach_certifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "certifications_read_gym" ON public.coach_certifications;
DROP POLICY IF EXISTS "certifications_insert_coach" ON public.coach_certifications;

CREATE POLICY "certifications_read_gym"
  ON public.coach_certifications FOR SELECT
  USING (gym_id::text = public.get_my_gym_id()::text);

CREATE POLICY "certifications_insert_coach"
  ON public.coach_certifications FOR INSERT
  WITH CHECK (
    gym_id::text = public.get_my_gym_id()::text
    AND public.get_my_role() = 'coach'
    AND coach_user_id::text = public.get_my_member_id()::text
    AND EXISTS (
      SELECT 1
      FROM public.posts p
      WHERE p.id = post_id
        AND p.gym_id::text = public.get_my_gym_id()::text
        AND p.workout_session_id IS NOT NULL
        AND p.user_id::text <> public.get_my_member_id()::text
        AND p.is_deleted = false
    )
  );
