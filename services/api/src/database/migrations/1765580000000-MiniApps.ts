// Made by Dr Ali
// Mini-app submissions: owner, HTTPS start URL, SuperAdmin review, kill switch.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MiniApps1765580000000 implements MigrationInterface {
  name = 'MiniApps1765580000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "mini_apps" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "owner_user_id" uuid NOT NULL,
        "name" varchar(80) NOT NULL,
        "description" varchar(400) NOT NULL DEFAULT '',
        "icon_url" varchar(1024) NULL,
        "start_url" varchar(2048) NOT NULL,
        "status" varchar(16) NOT NULL DEFAULT 'pending',
        "review_note" varchar(500) NULL,
        "reviewer_user_id" uuid NULL,
        "reviewed_at" TIMESTAMPTZ NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_mini_apps" PRIMARY KEY ("id"),
        CONSTRAINT "FK_mini_apps_owner"
          FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_mini_apps_reviewer"
          FOREIGN KEY ("reviewer_user_id") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_mini_apps_owner"
        ON "mini_apps" ("owner_user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_mini_apps_status"
        ON "mini_apps" ("status")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "mini_apps"`);
  }
}
