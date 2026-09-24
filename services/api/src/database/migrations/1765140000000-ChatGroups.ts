// Made by Dr Ali — group chats (Marketing Manager workflow) + optional title.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class ChatGroups1765140000000 implements MigrationInterface {
  name = 'ChatGroups1765140000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "conversations_kind_enum" ADD VALUE IF NOT EXISTS 'group'`,
    );
    await queryRunner.query(
      `ALTER TABLE "conversations" ADD COLUMN IF NOT EXISTS "title" character varying(120)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "conversations" DROP COLUMN IF EXISTS "title"`,
    );
    // Postgres cannot easily remove enum values — leave 'group' in place.
  }
}
