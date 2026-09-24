// Made by Dr Ali — customer service request form payload + sub-service label.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class OrderFormData1765320000000 implements MigrationInterface {
  name = 'OrderFormData1765320000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "orders"
        ADD COLUMN IF NOT EXISTS "sub_service_id" varchar(80) NULL,
        ADD COLUMN IF NOT EXISTS "sub_service_name_en" varchar(160) NULL,
        ADD COLUMN IF NOT EXISTS "sub_service_name_ar" varchar(160) NULL,
        ADD COLUMN IF NOT EXISTS "form_data" jsonb NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "orders"
        DROP COLUMN IF EXISTS "form_data",
        DROP COLUMN IF EXISTS "sub_service_name_ar",
        DROP COLUMN IF EXISTS "sub_service_name_en",
        DROP COLUMN IF EXISTS "sub_service_id"
    `);
  }
}
