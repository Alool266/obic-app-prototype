// Made by Dr Ali
// Phase 5 AI — conversation auto-reply flag + message is_ai marker.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Phase5Ai1765390000000 implements MigrationInterface {
  name = 'Phase5Ai1765390000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "conversations"
        ADD COLUMN IF NOT EXISTS "ai_auto_reply_enabled" boolean NOT NULL DEFAULT true
    `);
    await queryRunner.query(`
      ALTER TABLE "messages"
        ADD COLUMN IF NOT EXISTS "is_ai" boolean NOT NULL DEFAULT false
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "messages" DROP COLUMN IF EXISTS "is_ai"
    `);
    await queryRunner.query(`
      ALTER TABLE "conversations" DROP COLUMN IF EXISTS "ai_auto_reply_enabled"
    `);
  }
}
