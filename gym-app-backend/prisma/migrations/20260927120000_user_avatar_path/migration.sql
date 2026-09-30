-- Profile photo storage path inside the public avatars bucket.
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "avatar_path" TEXT;
