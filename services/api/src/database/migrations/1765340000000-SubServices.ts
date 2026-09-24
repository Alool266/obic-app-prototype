// Made by Dr Ali
// Admin-managed inner services (hub items) + seed from mobile catalog.

import { MigrationInterface, QueryRunner } from 'typeorm';
import { SUB_SERVICE_SEED } from '../../services/sub-service.seed';

export class SubServices1765340000000 implements MigrationInterface {
  name = 'SubServices1765340000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "service_subs" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "service_id" uuid NOT NULL,
        "external_id" character varying(80) NOT NULL,
        "icon" character varying(32) NOT NULL,
        "sort_order" integer NOT NULL DEFAULT 0,
        "name_ar" character varying(160) NOT NULL,
        "name_en" character varying(160) NOT NULL,
        "name_zh" character varying(160) NOT NULL DEFAULT '',
        "desc_ar" text NOT NULL DEFAULT '',
        "desc_en" text NOT NULL DEFAULT '',
        "desc_zh" text NOT NULL DEFAULT '',
        "price_ar" character varying(80) NOT NULL DEFAULT '',
        "price_en" character varying(80) NOT NULL DEFAULT '',
        "price_zh" character varying(80) NOT NULL DEFAULT '',
        "is_active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_service_subs" PRIMARY KEY ("id"),
        CONSTRAINT "FK_service_subs_service" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_service_subs_service_external"
        ON "service_subs" ("service_id", "external_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_service_subs_service_id" ON "service_subs" ("service_id")
    `);

    for (const item of SUB_SERVICE_SEED) {
      const rows = await queryRunner.query(
        `SELECT id FROM "services" WHERE slug = $1 LIMIT 1`,
        [item.parentSlug],
      );
      if (!Array.isArray(rows) || rows.length === 0) continue;
      const serviceId = rows[0].id as string;
      await queryRunner.query(
        `
        INSERT INTO "service_subs" (
          "service_id", "external_id", "icon", "sort_order",
          "name_ar", "name_en", "name_zh",
          "desc_ar", "desc_en", "desc_zh",
          "price_ar", "price_en", "price_zh"
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        `,
        [
          serviceId,
          item.id,
          item.icon,
          item.sortOrder,
          item.nameAr,
          item.nameEn,
          item.nameZh ?? '',
          item.descAr,
          item.descEn,
          item.descZh ?? '',
          item.priceAr,
          item.priceEn,
          item.priceZh ?? '',
        ],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "service_subs"`);
  }
}
