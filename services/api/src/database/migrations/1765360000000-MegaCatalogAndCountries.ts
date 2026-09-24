// Made by Dr Ali
// Catalog v2: country availability + WeChat-style 10 mega-categories.

import { MigrationInterface, QueryRunner } from 'typeorm';
import { MEGA_CATALOG_SEED } from '../../services/mega-catalog.seed';

const MEGA_SLUGS = MEGA_CATALOG_SEED.map((p) => p.slug);

export class MegaCatalogAndCountries1765360000000 implements MigrationInterface {
  name = 'MegaCatalogAndCountries1765360000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "services"
        ADD COLUMN IF NOT EXISTS "countries" jsonb NOT NULL DEFAULT '[]'
    `);
    await queryRunner.query(`
      ALTER TABLE "service_subs"
        ADD COLUMN IF NOT EXISTS "countries" jsonb NOT NULL DEFAULT '[]'
    `);

    await queryRunner.query(
      `UPDATE "services" SET "is_active" = false WHERE "slug" NOT IN (${MEGA_SLUGS.map((_, i) => `$${i + 1}`).join(', ')})`,
      MEGA_SLUGS,
    );

    for (const parent of MEGA_CATALOG_SEED) {
      const countriesJson = JSON.stringify(parent.countries ?? []);
      const existing = await queryRunner.query(
        `SELECT id FROM "services" WHERE slug = $1 LIMIT 1`,
        [parent.slug],
      );

      let serviceId: string;
      if (Array.isArray(existing) && existing.length > 0) {
        serviceId = existing[0].id as string;
        await queryRunner.query(
          `
          UPDATE "services" SET
            "icon" = $2,
            "color_key" = $3,
            "sort_order" = $4,
            "name_ar" = $5,
            "name_en" = $6,
            "name_zh" = $7,
            "desc_ar" = $8,
            "desc_en" = $9,
            "desc_zh" = $10,
            "price_ar" = $11,
            "price_en" = $12,
            "price_zh" = $13,
            "countries" = $14::jsonb,
            "is_active" = true
          WHERE "id" = $1
          `,
          [
            serviceId,
            parent.icon,
            parent.colorKey,
            parent.sortOrder,
            parent.nameAr,
            parent.nameEn,
            parent.nameZh,
            parent.descAr,
            parent.descEn,
            parent.descZh,
            parent.priceAr,
            parent.priceEn,
            parent.priceZh,
            countriesJson,
          ],
        );
      } else {
        const inserted = await queryRunner.query(
          `
          INSERT INTO "services" (
            "slug", "icon", "color_key", "sort_order",
            "name_ar", "name_en", "name_zh",
            "desc_ar", "desc_en", "desc_zh",
            "price_ar", "price_en", "price_zh",
            "countries", "is_active"
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14::jsonb,true)
          RETURNING id
          `,
          [
            parent.slug,
            parent.icon,
            parent.colorKey,
            parent.sortOrder,
            parent.nameAr,
            parent.nameEn,
            parent.nameZh,
            parent.descAr,
            parent.descEn,
            parent.descZh,
            parent.priceAr,
            parent.priceEn,
            parent.priceZh,
            countriesJson,
          ],
        );
        serviceId = inserted[0].id as string;
      }

      await queryRunner.query(
        `UPDATE "service_subs" SET "is_active" = false WHERE "service_id" = $1`,
        [serviceId],
      );

      for (const sub of parent.subs) {
        const subCountriesJson = JSON.stringify(sub.countries ?? []);
        const subExisting = await queryRunner.query(
          `SELECT id FROM "service_subs" WHERE "service_id" = $1 AND "external_id" = $2 LIMIT 1`,
          [serviceId, sub.id],
        );
        if (Array.isArray(subExisting) && subExisting.length > 0) {
          await queryRunner.query(
            `
            UPDATE "service_subs" SET
              "icon" = $2,
              "sort_order" = $3,
              "name_ar" = $4,
              "name_en" = $5,
              "name_zh" = $6,
              "desc_ar" = $7,
              "desc_en" = $8,
              "desc_zh" = $9,
              "price_ar" = $10,
              "price_en" = $11,
              "price_zh" = $12,
              "countries" = $13::jsonb,
              "is_active" = true
            WHERE "id" = $1
            `,
            [
              subExisting[0].id,
              sub.icon,
              sub.sortOrder,
              sub.nameAr,
              sub.nameEn,
              sub.nameZh,
              sub.descAr,
              sub.descEn,
              sub.descZh,
              sub.priceAr,
              sub.priceEn,
              sub.priceZh,
              subCountriesJson,
            ],
          );
        } else {
          await queryRunner.query(
            `
            INSERT INTO "service_subs" (
              "service_id", "external_id", "icon", "sort_order",
              "name_ar", "name_en", "name_zh",
              "desc_ar", "desc_en", "desc_zh",
              "price_ar", "price_en", "price_zh",
              "countries", "is_active"
            ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14::jsonb,true)
            `,
            [
              serviceId,
              sub.id,
              sub.icon,
              sub.sortOrder,
              sub.nameAr,
              sub.nameEn,
              sub.nameZh,
              sub.descAr,
              sub.descEn,
              sub.descZh,
              sub.priceAr,
              sub.priceEn,
              sub.priceZh,
              subCountriesJson,
            ],
          );
        }
      }
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "services" SET "is_active" = true
      WHERE "slug" IN (${MEGA_SLUGS.map((_, i) => `$${i + 1}`).join(', ')})
    `, MEGA_SLUGS);
    await queryRunner.query(`ALTER TABLE "service_subs" DROP COLUMN IF EXISTS "countries"`);
    await queryRunner.query(`ALTER TABLE "services" DROP COLUMN IF EXISTS "countries"`);
  }
}
