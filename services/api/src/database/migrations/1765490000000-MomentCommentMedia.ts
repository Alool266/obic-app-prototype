// Made by Dr Ali
// WeChat Moments comments: optional image attachments (jsonb media).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentCommentMedia1765490000000 implements MigrationInterface {
  name = 'MomentCommentMedia1765490000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        ADD COLUMN IF NOT EXISTS "media" jsonb NOT NULL DEFAULT '[]'::jsonb
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        DROP COLUMN IF EXISTS "media"
    `);
  }
}
