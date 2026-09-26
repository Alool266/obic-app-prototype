// Made by Dr Ali
// WeChat chat list: pin + force-unread; message recall within a short window.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class ChatPinUnreadRecall1765520000000 implements MigrationInterface {
  name = 'ChatPinUnreadRecall1765520000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "conversation_participants"
        ADD COLUMN IF NOT EXISTS "pinned" BOOLEAN NOT NULL DEFAULT false
    `);
    await queryRunner.query(`
      ALTER TABLE "conversation_participants"
        ADD COLUMN IF NOT EXISTS "force_unread" BOOLEAN NOT NULL DEFAULT false
    `);
    await queryRunner.query(`
      ALTER TABLE "messages"
        ADD COLUMN IF NOT EXISTS "recalled_at" TIMESTAMPTZ NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "messages" DROP COLUMN IF EXISTS "recalled_at"
    `);
    await queryRunner.query(`
      ALTER TABLE "conversation_participants" DROP COLUMN IF EXISTS "force_unread"
    `);
    await queryRunner.query(`
      ALTER TABLE "conversation_participants" DROP COLUMN IF EXISTS "pinned"
    `);
  }
}
