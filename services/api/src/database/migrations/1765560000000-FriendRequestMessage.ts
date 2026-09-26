// Made by Dr Ali
// WeChat-style verification note on friend requests.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class FriendRequestMessage1765560000000 implements MigrationInterface {
  name = 'FriendRequestMessage1765560000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "friend_requests"
        ADD COLUMN IF NOT EXISTS "message" character varying(120) NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "friend_requests"
        DROP COLUMN IF EXISTS "message"
    `);
  }
}
