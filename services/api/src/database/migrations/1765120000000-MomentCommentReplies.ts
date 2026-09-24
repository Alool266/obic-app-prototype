// Made by Dr Ali
// WeChat-style nested replies: reply_to_comment_id on moment_comments.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentCommentReplies1765120000000 implements MigrationInterface {
  name = 'MomentCommentReplies1765120000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        ADD COLUMN IF NOT EXISTS "reply_to_comment_id" uuid NULL
    `);
    await queryRunner.query(`
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
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_moment_comments_reply_to"
        ON "moment_comments" ("reply_to_comment_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "idx_moment_comments_reply_to"`,
    );
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        DROP CONSTRAINT IF EXISTS "fk_moment_comments_reply_to"
    `);
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        DROP COLUMN IF EXISTS "reply_to_comment_id"
    `);
  }
}
