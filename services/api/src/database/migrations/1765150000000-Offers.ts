// Made by Dr Ali
// Offers migration — staff hotel/flight listings with media jsonb.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Offers1765150000000 implements MigrationInterface {
  name = 'Offers1765150000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "offers" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "kind" character varying(32) NOT NULL,
        "title_ar" character varying(200) NOT NULL,
        "title_en" character varying(200) NOT NULL,
        "body_ar" text NOT NULL DEFAULT '',
        "body_en" text NOT NULL DEFAULT '',
        "price_label_ar" character varying(120),
        "price_label_en" character varying(120),
        "location_label" character varying(200),
        "dates_label" character varying(200),
        "media" jsonb NOT NULL DEFAULT '[]',
        "is_published" boolean NOT NULL DEFAULT false,
        "created_by_id" uuid NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "fk_offers_created_by"
          FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_kind" ON "offers" ("kind")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_published_kind" ON "offers" ("is_published", "kind")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "offers"`);
  }
}
