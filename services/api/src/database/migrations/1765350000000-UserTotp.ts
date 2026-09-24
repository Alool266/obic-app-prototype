// Made by Dr Ali
// SuperAdmin TOTP — encrypted secret storage on users table.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserTotp1765350000000 implements MigrationInterface {
  name = 'UserTotp1765350000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN "totp_secret_enc" text,
        ADD COLUMN "totp_pending_secret_enc" text,
        ADD COLUMN "totp_enabled" boolean NOT NULL DEFAULT false
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "totp_secret_enc",
        DROP COLUMN IF EXISTS "totp_pending_secret_enc",
        DROP COLUMN IF EXISTS "totp_enabled"
    `);
  }
}
