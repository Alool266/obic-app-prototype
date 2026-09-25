// Made by Dr Ali
// Moments cover, soft-delete users, chat mute/hide, app bug reports.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class WechatParitySettings1765450000000 implements MigrationInterface {
  name = 'WechatParitySettings1765450000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "moments_cover_url" varchar(1024) NULL,
        ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ NULL
    `);

    await queryRunner.query(`
      ALTER TABLE "conversation_participants"
        ADD COLUMN IF NOT EXISTS "muted" boolean NOT NULL DEFAULT false,
        ADD COLUMN IF NOT EXISTS "hidden" boolean NOT NULL DEFAULT false,
        ADD COLUMN IF NOT EXISTS "cleared_before" TIMESTAMPTZ NULL
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "bug_reports" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "description" text NOT NULL,
        "photo_urls" jsonb NOT NULL DEFAULT '[]'::jsonb,
        "status" varchar(32) NOT NULL DEFAULT 'open',
        "reviewed_by" uuid NULL,
        "reviewed_at" TIMESTAMPTZ NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_bug_reports" PRIMARY KEY ("id"),
        CONSTRAINT "FK_bug_reports_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_bug_reports_status"
        ON "bug_reports" ("status")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_bug_reports_created"
        ON "bug_reports" ("created_at" DESC)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "bug_reports"`);
    await queryRunner.query(`
      ALTER TABLE "conversation_participants"
        DROP COLUMN IF EXISTS "cleared_before",
        DROP COLUMN IF EXISTS "hidden",
        DROP COLUMN IF EXISTS "muted"
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "deleted_at",
        DROP COLUMN IF EXISTS "moments_cover_url"
    `);
  }
}
