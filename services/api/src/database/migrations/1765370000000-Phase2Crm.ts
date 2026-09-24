// Made by Dr Ali
// Phase 2 CRM — order-linked chat + Assigned / WaitingCustomer statuses.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Phase2Crm1765370000000 implements MigrationInterface {
  name = 'Phase2Crm1765370000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "orders_status_enum" ADD VALUE IF NOT EXISTS 'Assigned'`,
    );
    await queryRunner.query(
      `ALTER TYPE "orders_status_enum" ADD VALUE IF NOT EXISTS 'WaitingCustomer'`,
    );

    await queryRunner.query(
      `ALTER TYPE "conversations_kind_enum" ADD VALUE IF NOT EXISTS 'order'`,
    );

    await queryRunner.query(`
      ALTER TABLE "conversations"
        ADD COLUMN IF NOT EXISTS "order_id" uuid,
        ADD CONSTRAINT "FK_conversations_order"
          FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_conversations_order_id"
        ON "conversations" ("order_id")
        WHERE "order_id" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_conversations_order_id"`);
    await queryRunner.query(`
      ALTER TABLE "conversations" DROP CONSTRAINT IF EXISTS "FK_conversations_order"
    `);
    await queryRunner.query(`
      ALTER TABLE "conversations" DROP COLUMN IF EXISTS "order_id"
    `);
  }
}
