// Made by Dr Ali
// WeChat Moments visibility: public (official) | friends (mutual only).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentVisibility1765410000000 implements MigrationInterface {
  name = 'MomentVisibility1765410000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moments"
        ADD COLUMN IF NOT EXISTS "visibility" character varying(16)
          NOT NULL DEFAULT 'friends'
    `);
    // Official / staff posts that notified everyone → public.
    await queryRunner.query(`
      UPDATE "moments"
         SET "visibility" = 'public'
       WHERE "notify_all" = true
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_moments_visibility"
        ON "moments" ("visibility")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_moments_visibility"`);
    await queryRunner.query(`
      ALTER TABLE "moments" DROP COLUMN IF EXISTS "visibility"
    `);
  }
}
