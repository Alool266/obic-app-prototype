// Made by Dr Ali
// Customer saved addresses for food delivery and service requests.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserAddresses1765380000000 implements MigrationInterface {
  name = 'UserAddresses1765380000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "addresses" jsonb NOT NULL DEFAULT '[]'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "addresses"
    `);
  }
}
