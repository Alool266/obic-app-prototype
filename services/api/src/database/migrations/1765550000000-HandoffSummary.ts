// Made by Dr Ali
// Persist AI / structured handoff briefing for Secretary on support/order threads.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class HandoffSummary1765550000000 implements MigrationInterface {
  name = 'HandoffSummary1765550000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "conversations"
        ADD COLUMN IF NOT EXISTS "handoff_summary" text NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "conversations"
        DROP COLUMN IF EXISTS "handoff_summary"
    `);
  }
}
