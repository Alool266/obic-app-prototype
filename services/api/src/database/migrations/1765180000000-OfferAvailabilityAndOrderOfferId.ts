// Made by Dr Ali
// Offer sold-out / expiry flags + optional order.offer_id link for customer requests.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class OfferAvailabilityAndOrderOfferId1765180000000
  implements MigrationInterface
{
  name = 'OfferAvailabilityAndOrderOfferId1765180000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "offers"
        ADD COLUMN IF NOT EXISTS "is_sold_out" boolean NOT NULL DEFAULT false
    `);
    await queryRunner.query(`
      ALTER TABLE "offers"
        ADD COLUMN IF NOT EXISTS "expires_at" TIMESTAMPTZ NULL
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_offers_public_browse"
        ON "offers" ("is_published", "is_sold_out", "expires_at", "kind")
    `);

    await queryRunner.query(`
      ALTER TABLE "orders"
        ADD COLUMN IF NOT EXISTS "offer_id" uuid NULL
    `);
    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'FK_orders_offer_id'
        ) THEN
          ALTER TABLE "orders"
            ADD CONSTRAINT "FK_orders_offer_id"
            FOREIGN KEY ("offer_id") REFERENCES "offers"("id")
            ON DELETE SET NULL;
        END IF;
      END $$;
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_orders_offer_id" ON "orders" ("offer_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_orders_offer_id"`);
    await queryRunner.query(`
      ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "FK_orders_offer_id"
    `);
    await queryRunner.query(`
      ALTER TABLE "orders" DROP COLUMN IF EXISTS "offer_id"
    `);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_offers_public_browse"`);
    await queryRunner.query(`
      ALTER TABLE "offers" DROP COLUMN IF EXISTS "expires_at"
    `);
    await queryRunner.query(`
      ALTER TABLE "offers" DROP COLUMN IF EXISTS "is_sold_out"
    `);
  }
}
