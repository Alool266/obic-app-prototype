// Made by Dr Ali
// Extend messages.attachment_kind enum with audio + video (voice notes / clips).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class ChatAudioVideoAttachments1765470000000 implements MigrationInterface {
  name = 'ChatAudioVideoAttachments1765470000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ADD VALUE cannot run inside a transaction on older PG; IF NOT EXISTS is safe.
    await queryRunner.query(`
      ALTER TYPE "messages_attachment_kind_enum" ADD VALUE IF NOT EXISTS 'audio'
    `);
    await queryRunner.query(`
      ALTER TYPE "messages_attachment_kind_enum" ADD VALUE IF NOT EXISTS 'video'
    `);
  }

  public async down(): Promise<void> {
    // Postgres cannot remove enum values safely; leave audio/video in place.
  }
}
