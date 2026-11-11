-- =============================================================================
-- Migration 004: Phase 3 — AI Companion + Payments + Data Import
-- Run this when starting Phase 3 development
-- =============================================================================

-- =============================================================================
-- NEW TABLE: ai_conversations
-- One conversation per user. Conversations group messages for context window.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "ai_conversations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "ai_conversations_user_id_key"
    ON "ai_conversations"("user_id");

ALTER TABLE "ai_conversations"
    ADD CONSTRAINT "ai_conversations_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TRIGGER update_ai_conversations_updated_at
    BEFORE UPDATE ON ai_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- NEW TABLE: ai_messages
-- Individual turns in the AI conversation.
-- token_count is tracked here for cost monitoring per user.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "ai_messages" (
    "id" TEXT NOT NULL,
    "conversation_id" TEXT NOT NULL,
    "role" TEXT NOT NULL,               -- user / assistant / system
    "content" TEXT NOT NULL,
    "token_count" INTEGER,              -- track for cost monitoring
    "model" TEXT,                       -- e.g. claude-haiku-3, gpt-4o-mini
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "ai_messages_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "ai_messages_conversation_id_idx"
    ON "ai_messages"("conversation_id");

CREATE INDEX IF NOT EXISTS "ai_messages_created_at_idx"
    ON "ai_messages"("created_at" DESC);

ALTER TABLE "ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey"
    FOREIGN KEY ("conversation_id") REFERENCES "ai_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- =============================================================================
-- NEW TABLE: subscriptions
-- Premium tier tracking per user.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "gym_id" TEXT NOT NULL,
    "tier" TEXT NOT NULL DEFAULT 'free',           -- free / premium
    "status" TEXT NOT NULL DEFAULT 'active',       -- active / cancelled / expired / trial
    "payment_provider" TEXT,                       -- mpesa / stripe / manual
    "provider_reference" TEXT,                     -- M-Pesa confirmation code or Stripe sub ID
    "started_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "expires_at" TIMESTAMPTZ,
    "cancelled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "subscriptions_user_id_idx" ON "subscriptions"("user_id");
CREATE INDEX IF NOT EXISTS "subscriptions_gym_id_idx" ON "subscriptions"("gym_id");
CREATE INDEX IF NOT EXISTS "subscriptions_status_idx" ON "subscriptions"("status");

ALTER TABLE "subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "subscriptions"
    ADD CONSTRAINT "subscriptions_gym_id_fkey"
    FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- NEW TABLE: payment_events
-- Audit log of every webhook event from M-Pesa / Stripe.
-- Never delete rows from this table.
-- =============================================================================

CREATE TABLE IF NOT EXISTS "payment_events" (
    "id" TEXT NOT NULL,
    "user_id" TEXT,                     -- nullable — some webhooks arrive before user lookup
    "provider" TEXT NOT NULL,           -- mpesa / stripe
    "event_type" TEXT NOT NULL,         -- payment.completed, subscription.cancelled, etc.
    "provider_reference" TEXT,          -- provider's transaction/event ID
    "amount" NUMERIC(12,2),
    "currency" TEXT DEFAULT 'KES',
    "payload" JSONB,                    -- full raw webhook payload
    "processed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "payment_events_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "payment_events_user_id_idx" ON "payment_events"("user_id");
CREATE INDEX IF NOT EXISTS "payment_events_provider_reference_idx" ON "payment_events"("provider_reference");
CREATE INDEX IF NOT EXISTS "payment_events_created_at_idx" ON "payment_events"("created_at" DESC);

-- =============================================================================
-- NEW TABLE: import_jobs
-- Background job queue for data imports (Strong, Hevy, Apple Health, CSV)
-- =============================================================================

CREATE TABLE IF NOT EXISTS "import_jobs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "source_type" TEXT NOT NULL,        -- generic_csv / strong / hevy / apple_health
    "status" TEXT NOT NULL DEFAULT 'pending', -- pending / processing / completed / failed
    "raw_file_url" TEXT,                -- Supabase Storage URL of uploaded file
    "rows_total" INTEGER,
    "rows_processed" INTEGER NOT NULL DEFAULT 0,
    "rows_failed" INTEGER NOT NULL DEFAULT 0,
    "error_log" TEXT,
    "started_at" TIMESTAMPTZ,
    "completed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "import_jobs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "import_jobs_user_id_idx" ON "import_jobs"("user_id");
CREATE INDEX IF NOT EXISTS "import_jobs_status_idx" ON "import_jobs"("status");

ALTER TABLE "import_jobs"
    ADD CONSTRAINT "import_jobs_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TRIGGER update_import_jobs_updated_at
    BEFORE UPDATE ON import_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
