-- CreateTable
CREATE TABLE "post_flags" (
    "id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_flags_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "post_flags_post_id_idx" ON "post_flags"("post_id");

-- CreateIndex
CREATE UNIQUE INDEX "post_flags_post_id_user_id_key" ON "post_flags"("post_id", "user_id");

-- AddForeignKey
ALTER TABLE "post_flags" ADD CONSTRAINT "post_flags_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_flags" ADD CONSTRAINT "post_flags_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
