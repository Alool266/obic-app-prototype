// Made by Dr Ali
// Profile gender + What's Up (WeChat-style signature) on users.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserGenderWhatsUp1765530000000 implements MigrationInterface {
  name = 'UserGenderWhatsUp1765530000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "gender" varchar(16) NULL
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "whats_up" varchar(120) NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "whats_up"
    `);
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "gender"
    `);
  }
}
