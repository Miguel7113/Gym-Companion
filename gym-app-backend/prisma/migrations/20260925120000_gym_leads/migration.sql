-- Marketing site "Propose your gym" applications
CREATE TABLE IF NOT EXISTS "gym_leads" (
    "id" TEXT NOT NULL,
    "gym_name" TEXT NOT NULL,
    "contact_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "city" TEXT,
    "member_count" TEXT,
    "message" TEXT,
    "status" TEXT NOT NULL DEFAULT 'NEW',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "gym_leads_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "gym_leads_status_created_at_idx"
    ON "gym_leads"("status", "created_at" DESC);
