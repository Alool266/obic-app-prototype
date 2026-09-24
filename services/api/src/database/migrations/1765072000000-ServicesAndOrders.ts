// Made by Dr Ali
// Phase 2: public services catalog + customer orders (JWT ownership).

import { MigrationInterface, QueryRunner } from 'typeorm';
import { CATALOG_SEED } from '../../services/catalog.seed';

export class ServicesAndOrders1765072000000 implements MigrationInterface {
  name = 'ServicesAndOrders1765072000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "services" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "slug" character varying(64) NOT NULL,
        "icon" character varying(32) NOT NULL,
        "color_key" character varying(32),
        "sort_order" integer NOT NULL DEFAULT 0,
        "name_ar" character varying(120) NOT NULL,
        "name_en" character varying(120) NOT NULL,
        "desc_ar" text NOT NULL,
        "desc_en" text NOT NULL,
        "price_ar" character varying(80) NOT NULL,
        "price_en" character varying(80) NOT NULL,
        "is_active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_services_slug" UNIQUE ("slug"),
        CONSTRAINT "PK_services" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TYPE "orders_status_enum" AS ENUM (
        'Submitted', 'InProgress', 'Completed', 'Cancelled'
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "orders" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "service_id" uuid NOT NULL,
        "status" "orders_status_enum" NOT NULL DEFAULT 'Submitted',
        "preferred_branch" character varying(80),
        "notes" text,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_orders" PRIMARY KEY ("id"),
        CONSTRAINT "FK_orders_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_orders_service"
          FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_orders_user_id" ON "orders" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_orders_service_id" ON "orders" ("service_id")
    `);

    for (const item of CATALOG_SEED) {
      await queryRunner.query(
        `
        INSERT INTO "services" (
          "slug", "icon", "color_key", "sort_order",
          "name_ar", "name_en", "desc_ar", "desc_en",
          "price_ar", "price_en"
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        `,
        [
          item.slug,
          item.icon,
          item.colorKey,
          item.sortOrder,
          item.nameAr,
          item.nameEn,
          item.descAr,
          item.descEn,
          item.priceAr,
          item.priceEn,
        ],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "orders"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "orders_status_enum"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "services"`);
  }
}
