// Made by Dr Ali
// Hotel & flight offers access — SuperAdmin grants per Employee; default off.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserOffersAccess1765170000000 implements MigrationInterface {
  name = 'UserOffersAccess1765170000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "offers_access" boolean NOT NULL DEFAULT false
    `);
    // SuperAdmin always may manage offers; keep DB consistent for staff desk toggles.
    await queryRunner.query(`
      UPDATE "users"
      SET "offers_access" = true
      WHERE "role" = 'SuperAdmin'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "offers_access"
    `);
  }
}
