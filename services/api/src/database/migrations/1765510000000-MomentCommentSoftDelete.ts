// Made by Dr Ali
// Soft-delete for Moments comments (WeChat-style delete by author / post owner).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentCommentSoftDelete1765510000000 implements MigrationInterface {
  name = 'MomentCommentSoftDelete1765510000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moment_comments"
        DROP COLUMN IF EXISTS "deleted_at"
    `);
  }
}
