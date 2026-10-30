// Made by Dr Ali
// Mini-app shelf on home-layout + personal Notes/Docs/Sheets/PDF + desk flags.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MiniAppsLayoutAndUserOffice1765930000000
  implements MigrationInterface
{
  name = 'MiniAppsLayoutAndUserOffice1765930000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "user_home_layouts"
        ADD COLUMN IF NOT EXISTS "mini_order" jsonb NOT NULL DEFAULT '[]',
        ADD COLUMN IF NOT EXISTS "mini_favorites" jsonb NOT NULL DEFAULT '[]',
        ADD COLUMN IF NOT EXISTS "mini_hidden" jsonb NOT NULL DEFAULT '[]'
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "user_office_items" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "kind" varchar(20) NOT NULL,
        "title" varchar(120) NOT NULL DEFAULT '',
        "body" text NOT NULL DEFAULT '',
        "grid" jsonb NOT NULL DEFAULT '[]',
        "file_url" varchar(500),
        "share_user_ids" jsonb NOT NULL DEFAULT '[]',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_user_office_items" PRIMARY KEY ("id"),
        CONSTRAINT "FK_user_office_items_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_user_office_items_kind"
          CHECK ("kind" IN ('note', 'document', 'spreadsheet', 'pdf'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_user_office_items_owner_kind"
        ON "user_office_items" ("user_id", "kind")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "desk_mini_app_flags" (
        "app_id" varchar(64) NOT NULL,
        "enabled" boolean NOT NULL DEFAULT true,
        "updated_by" uuid,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_desk_mini_app_flags" PRIMARY KEY ("app_id")
      )
    `);

    await queryRunner.query(`
      INSERT INTO "desk_mini_app_flags" ("app_id", "enabled") VALUES
        ('obic-notes', true),
        ('obic-documents', true),
        ('obic-spreadsheets', true),
        ('obic-pdf', true),
        ('obic-slides', false),
        ('obic-china-in-hand', true),
        ('obic-mideast-in-hand', true),
        ('obic-africa-in-hand', true),
        ('obic-daily', true),
        ('obic-travel', true),
        ('obic-yemen-in-hand', true),
        ('obic-music', true),
        ('obic-web', true)
      ON CONFLICT ("app_id") DO NOTHING
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "desk_mini_app_flags"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "user_office_items"`);
    await queryRunner.query(`
      ALTER TABLE "user_home_layouts"
        DROP COLUMN IF EXISTS "mini_order",
        DROP COLUMN IF EXISTS "mini_favorites",
        DROP COLUMN IF EXISTS "mini_hidden"
    `);
  }
}
