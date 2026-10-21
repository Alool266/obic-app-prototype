// Made by Dr Ali
// Link Google / Apple subjects to an existing user (nullable; many nulls allowed).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserSocialSubjects1765570000000 implements MigrationInterface {
  name = 'UserSocialSubjects1765570000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "google_sub" character varying(255) NULL,
        ADD COLUMN IF NOT EXISTS "apple_sub" character varying(255) NULL
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_users_google_sub"
        ON "users" ("google_sub")
        WHERE "google_sub" IS NOT NULL
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_users_apple_sub"
        ON "users" ("apple_sub")
        WHERE "apple_sub" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_users_apple_sub"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_users_google_sub"`);
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "apple_sub",
        DROP COLUMN IF EXISTS "google_sub"
    `);
  }
}
