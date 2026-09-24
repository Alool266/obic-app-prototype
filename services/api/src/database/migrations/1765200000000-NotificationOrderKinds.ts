// Made by Dr Ali
// Phase B: order inbox kinds + composite (user_id, created_at) index.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class NotificationOrderKinds1765200000000 implements MigrationInterface {
  name = 'NotificationOrderKinds1765200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "notifications_kind_enum" ADD VALUE IF NOT EXISTS 'order_created'`,
    );
    await queryRunner.query(
      `ALTER TYPE "notifications_kind_enum" ADD VALUE IF NOT EXISTS 'order_status'`,
    );
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_notifications_user_created"
      ON "notifications" ("user_id", "created_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_notifications_user_created"`,
    );
    // Postgres cannot easily remove enum values — leave order kinds in place.
  }
}
