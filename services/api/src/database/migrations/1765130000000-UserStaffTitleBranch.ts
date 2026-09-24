// Made by Dr Ali
// Optional staff desk title + branch label (display only — AuthZ stays on UserRole).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserStaffTitleBranch1765130000000 implements MigrationInterface {
  name = 'UserStaffTitleBranch1765130000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "staff_title" varchar(120) NULL
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "branch_label" varchar(120) NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "branch_label"
    `);
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "staff_title"
    `);
  }
}
