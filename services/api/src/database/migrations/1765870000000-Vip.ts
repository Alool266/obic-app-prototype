// Made by Dr Ali
// VIP module (boss M06): vip_trips + vip_consultations, and Draft price seeds
// for the two separate VIP products — timed consultations (USD, Master
// Handoff §9) and trip coordination fees (CNY exact-day table, VIP Spec §2).
// Draft only: nothing is customer-visible until SuperAdmin approval.

import { MigrationInterface, QueryRunner } from 'typeorm';

const VERSION = 'boss-2026-10-v1';
const SOURCE = 'Boss Final Developer Execution Package v1.0 (Oct 2026)';

export class Vip1765870000000 implements MigrationInterface {
  name = 'Vip1765870000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "vip_consultations" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "minutes" integer NOT NULL,
        "price_id" varchar(64) NOT NULL,
        "price_snapshot" jsonb,
        "status" varchar(24) NOT NULL DEFAULT 'PENDING_PAYMENT',
        "paid_reference" varchar(120),
        "staff_user_id" uuid,
        "started_at" TIMESTAMP WITH TIME ZONE,
        "ends_at" TIMESTAMP WITH TIME ZONE,
        "ended_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_vip_consultations" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_vip_consultations_status"
          CHECK ("status" IN ('PENDING_PAYMENT','READY','ACTIVE','ENDED','CANCELLED')),
        CONSTRAINT "CHK_vip_consultations_minutes"
          CHECK ("minutes" IN (10,20,30,60))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_vip_consultations_user"
      ON "vip_consultations" ("user_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "vip_trips" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "tracking_id" varchar(32) NOT NULL,
        "purpose" varchar(8) NOT NULL,
        "cities" jsonb NOT NULL,
        "days" integer NOT NULL,
        "people" integer NOT NULL DEFAULT 1,
        "budget_cents" integer,
        "status" varchar(24) NOT NULL DEFAULT 'DRAFT',
        "quotation" jsonb,
        "quotation_version" integer NOT NULL DEFAULT 0,
        "accepted_at" TIMESTAMP WITH TIME ZONE,
        "paid_reference" varchar(120),
        "group_conversation_id" uuid,
        "assigned_employee_id" uuid,
        "notes" text,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_vip_trips" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_vip_trips_tracking" UNIQUE ("tracking_id"),
        CONSTRAINT "CHK_vip_trips_status"
          CHECK ("status" IN ('DRAFT','QUOTED','ACCEPTED','GROUP_CREATED','IN_PROGRESS','COMPLETED','CANCELLED')),
        CONSTRAINT "CHK_vip_trips_purpose"
          CHECK ("purpose" IN ('BIZ','TOUR','MED','STU','INV','MIX'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_vip_trips_user" ON "vip_trips" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_vip_trips_status" ON "vip_trips" ("status")
    `);

    // Timed consultations — USD (Master Handoff §9: 10/18/26/50).
    const consults: Array<[string, string, number]> = [
      ['PRICE-VIP-CONSULT-10', 'VIP consultation — 10 minutes', 1000],
      ['PRICE-VIP-CONSULT-20', 'VIP consultation — 20 minutes', 1800],
      ['PRICE-VIP-CONSULT-30', 'VIP consultation — 30 minutes', 2600],
      ['PRICE-VIP-CONSULT-60', 'VIP consultation — 60 minutes', 5000],
    ];
    for (const [priceId, itemName, cents] of consults) {
      await queryRunner.query(
        `
        INSERT INTO "price_versions"
          ("price_id", "version", "service_key", "item_name", "city",
           "obic_fee_cents", "external_fee_cents", "currency", "pricing_basis",
           "status", "source_ref")
        VALUES ($1, $2, 'vip-consultation', $3, NULL, $4, 0, 'USD', 'per_order',
                'Draft', $5)
        ON CONFLICT ("price_id", "version") DO NOTHING
        `,
        [priceId, VERSION, itemName, cents, SOURCE],
      );
    }

    // Trip coordination fees — CNY exact-day table (VIP Spec §2).
    const trips: Array<[number, number]> = [
      [5, 10000],
      [10, 15000],
      [15, 20000],
      [20, 25000],
      [30, 35000],
      [60, 65000],
    ];
    for (const [days, yuan] of trips) {
      await queryRunner.query(
        `
        INSERT INTO "price_versions"
          ("price_id", "version", "service_key", "item_name", "city",
           "obic_fee_cents", "external_fee_cents", "currency", "pricing_basis",
           "status", "source_ref")
        VALUES ($1, $2, 'vip-trip', $3, NULL, $4, 0, 'CNY', 'per_order',
                'Draft', $5)
        ON CONFLICT ("price_id", "version") DO NOTHING
        `,
        [
          `PRICE-VIP-TRIP-${days}D`,
          VERSION,
          `VIP trip coordination — ${days} days`,
          yuan * 100,
          SOURCE,
        ],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "vip_trips"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "vip_consultations"`);
  }
}
