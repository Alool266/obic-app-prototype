// Made by Dr Ali
// OBIC ID (WeChat-style vanity handle) + once-per-year change timestamp.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserObicId1765440000000 implements MigrationInterface {
  name = 'UserObicId1765440000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "obic_id" varchar(20) NULL,
        ADD COLUMN IF NOT EXISTS "obic_id_changed_at" TIMESTAMPTZ NULL
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_users_obic_id"
        ON "users" ("obic_id")
        WHERE "obic_id" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_users_obic_id"`);
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "obic_id_changed_at",
        DROP COLUMN IF EXISTS "obic_id"
    `);
  }
}
