// Made by Dr Ali
// Hosted mini-app package files, version link, and a short-lived preview ticket.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MiniAppPackages1765590000000 implements MigrationInterface {
  name = 'MiniAppPackages1765590000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "mini_apps"
        ADD COLUMN IF NOT EXISTS "supersedes_id" uuid NULL,
        ADD COLUMN IF NOT EXISTS "preview_ticket" varchar(80) NULL
    `);
    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'FK_mini_apps_supersedes'
        ) THEN
          ALTER TABLE "mini_apps"
            ADD CONSTRAINT "FK_mini_apps_supersedes"
            FOREIGN KEY ("supersedes_id") REFERENCES "mini_apps"("id")
            ON DELETE SET NULL;
        END IF;
      END $$;
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "mini_app_files" (
        "mini_app_id" uuid NOT NULL,
        "path" varchar(512) NOT NULL,
        "mime" varchar(128) NOT NULL,
        "size" integer NOT NULL,
        "data" bytea NOT NULL,
        CONSTRAINT "PK_mini_app_files" PRIMARY KEY ("mini_app_id", "path"),
        CONSTRAINT "FK_mini_app_files_app"
          FOREIGN KEY ("mini_app_id") REFERENCES "mini_apps"("id") ON DELETE CASCADE
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "mini_app_files"`);
    await queryRunner.query(`
      ALTER TABLE "mini_apps" DROP CONSTRAINT IF EXISTS "FK_mini_apps_supersedes"
    `);
    await queryRunner.query(`
      ALTER TABLE "mini_apps"
        DROP COLUMN IF EXISTS "preview_ticket",
        DROP COLUMN IF EXISTS "supersedes_id"
    `);
  }
}
