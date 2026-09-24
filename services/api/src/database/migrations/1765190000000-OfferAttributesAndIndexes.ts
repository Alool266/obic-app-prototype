// Made by Dr Ali
// Flexible offers: jsonb attributes + missing indexes (kind / published / created_by).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class OfferAttributesAndIndexes1765190000000
  implements MigrationInterface
{
  name = 'OfferAttributesAndIndexes1765190000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "offers"
        ADD COLUMN IF NOT EXISTS "attributes" jsonb NOT NULL DEFAULT '{}'::jsonb
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_kind" ON "offers" ("kind")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_is_published" ON "offers" ("is_published")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_created_by_id" ON "offers" ("created_by_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_offers_published_kind" ON "offers" ("is_published", "kind")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_offers_created_by_id"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_offers_is_published"`);
    await queryRunner.query(`
      ALTER TABLE "offers" DROP COLUMN IF EXISTS "attributes"
    `);
  }
}
