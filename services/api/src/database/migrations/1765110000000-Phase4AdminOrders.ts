// Made by Dr Ali
// Phase 4: order assignment for Employee queue scoping.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Phase4AdminOrders1765110000000 implements MigrationInterface {
  name = 'Phase4AdminOrders1765110000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "orders"
      ADD COLUMN IF NOT EXISTS "assigned_employee_id" uuid
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_orders_assigned_employee"
      ON "orders" ("assigned_employee_id")
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        ALTER TABLE "orders"
        ADD CONSTRAINT "FK_orders_assigned_employee"
        FOREIGN KEY ("assigned_employee_id") REFERENCES "users"("id")
        ON DELETE SET NULL;
      EXCEPTION WHEN duplicate_object THEN NULL;
      END $$;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "FK_orders_assigned_employee"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_orders_assigned_employee"`,
    );
    await queryRunner.query(
      `ALTER TABLE "orders" DROP COLUMN IF EXISTS "assigned_employee_id"`,
    );
  }
}
