-- Made by Dr Ali
-- WeChat-style comment replies: optional parent comment on the same moment.

ALTER TABLE "moment_comments"
  ADD COLUMN IF NOT EXISTS "reply_to_comment_id" uuid NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_moment_comments_reply_to'
  ) THEN
    ALTER TABLE "moment_comments"
      ADD CONSTRAINT "fk_moment_comments_reply_to"
      FOREIGN KEY ("reply_to_comment_id")
      REFERENCES "moment_comments"("id")
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "idx_moment_comments_reply_to"
  ON "moment_comments" ("reply_to_comment_id");
