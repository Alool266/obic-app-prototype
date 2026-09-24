// Made by Dr Ali
// Internal Ops access — SuperAdmin grants per Employee; default off.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserOpsAccess1765160000000 implements MigrationInterface {
  name = 'UserOpsAccess1765160000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "ops_access" boolean NOT NULL DEFAULT false
    `);
    // SuperAdmin always has Ops; keep DB consistent for staff desk toggles.
    await queryRunner.query(`
      UPDATE "users"
      SET "ops_access" = true
      WHERE "role" = 'SuperAdmin'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "ops_access"
    `);
  }
}
