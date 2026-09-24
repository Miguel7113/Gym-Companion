-- Gym buddies, shared session participants, in-app notifications

CREATE TABLE IF NOT EXISTS "gym_buddy_links" (
  "id" TEXT PRIMARY KEY,
  "gym_id" TEXT NOT NULL REFERENCES "gyms"("id") ON DELETE CASCADE,
  "user_a_id" TEXT NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "user_b_id" TEXT NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "requested_by_user_id" TEXT NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "status" TEXT NOT NULL DEFAULT 'pending',
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "gym_buddy_links_gym_id_user_a_id_user_b_id_key" UNIQUE ("gym_id", "user_a_id", "user_b_id")
);

CREATE INDEX IF NOT EXISTS "gym_buddy_links_gym_id_status_idx" ON "gym_buddy_links"("gym_id", "status");
CREATE INDEX IF NOT EXISTS "gym_buddy_links_user_a_id_idx" ON "gym_buddy_links"("user_a_id");
CREATE INDEX IF NOT EXISTS "gym_buddy_links_user_b_id_idx" ON "gym_buddy_links"("user_b_id");

CREATE TABLE IF NOT EXISTS "workout_session_participants" (
  "session_id" TEXT NOT NULL REFERENCES "workout_sessions"("id") ON DELETE CASCADE,
  "user_id" TEXT NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "role" TEXT NOT NULL DEFAULT 'buddy',
  "joined_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY ("session_id", "user_id")
);

CREATE INDEX IF NOT EXISTS "workout_session_participants_user_id_idx"
  ON "workout_session_participants"("user_id");

CREATE TABLE IF NOT EXISTS "app_notifications" (
  "id" TEXT PRIMARY KEY,
  "gym_id" TEXT NOT NULL REFERENCES "gyms"("id") ON DELETE CASCADE,
  "user_id" TEXT NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "type" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "payload_json" JSONB,
  "read_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS "app_notifications_user_id_created_at_idx"
  ON "app_notifications"("user_id", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "app_notifications_gym_id_idx" ON "app_notifications"("gym_id");
