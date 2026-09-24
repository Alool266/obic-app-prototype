// Made by Dr Ali
// Phase 1: Chinese (zh) labels + six new home service categories.

import { MigrationInterface, QueryRunner } from 'typeorm';
import { CATALOG_SEED } from '../../services/catalog.seed';

const PHASE1_NEW_SLUGS = [
  'cars',
  'property',
  'delivery',
  'consultations',
  'translation',
  'tourism',
] as const;

export class ServiceZhAndPhase1Categories1765330000000
  implements MigrationInterface
{
  name = 'ServiceZhAndPhase1Categories1765330000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "services"
        ADD COLUMN IF NOT EXISTS "name_zh" character varying(120) NOT NULL DEFAULT '',
        ADD COLUMN IF NOT EXISTS "desc_zh" text NOT NULL DEFAULT '',
        ADD COLUMN IF NOT EXISTS "price_zh" character varying(80) NOT NULL DEFAULT ''
    `);

    for (const item of CATALOG_SEED) {
      await queryRunner.query(
        `
        UPDATE "services" SET
          "name_zh" = $2,
          "desc_zh" = $3,
          "price_zh" = $4
        WHERE "slug" = $1
        `,
        [item.slug, item.nameZh, item.descZh, item.priceZh],
      );
    }

    for (const item of CATALOG_SEED) {
      if (!PHASE1_NEW_SLUGS.includes(item.slug as (typeof PHASE1_NEW_SLUGS)[number])) {
        continue;
      }
      const exists = await queryRunner.query(
        `SELECT 1 FROM "services" WHERE "slug" = $1 LIMIT 1`,
        [item.slug],
      );
      if (Array.isArray(exists) && exists.length > 0) continue;

      await queryRunner.query(
        `
        INSERT INTO "services" (
          "slug", "icon", "color_key", "sort_order",
          "name_ar", "name_en", "name_zh",
          "desc_ar", "desc_en", "desc_zh",
          "price_ar", "price_en", "price_zh"
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        `,
        [
          item.slug,
          item.icon,
          item.colorKey,
          item.sortOrder,
          item.nameAr,
          item.nameEn,
          item.nameZh,
          item.descAr,
          item.descEn,
          item.descZh,
          item.priceAr,
          item.priceEn,
          item.priceZh,
        ],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const slug of PHASE1_NEW_SLUGS) {
      await queryRunner.query(`DELETE FROM "services" WHERE "slug" = $1`, [slug]);
    }
    await queryRunner.query(`
      ALTER TABLE "services"
        DROP COLUMN IF EXISTS "name_zh",
        DROP COLUMN IF EXISTS "desc_zh",
        DROP COLUMN IF EXISTS "price_zh"
    `);
  }
}
