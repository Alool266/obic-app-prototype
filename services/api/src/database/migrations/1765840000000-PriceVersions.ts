// Made by Dr Ali
// Versioned prices (boss M02/M15). Seeds the boss October company-registration
// matrix as Draft rows only — nothing is customer-visible until a SuperAdmin
// moves it Review → Approved → Active with an effective date.
// Dongguan registration is deliberately omitted: the boss files conflict
// ("not specified" vs ¥3,500) and management must confirm it first.

import { MigrationInterface, QueryRunner } from 'typeorm';

type CityPrices = {
  code: string;
  city: string;
  registration: number;
  consulting: number;
  accountantNoTax: number;
  workResidence: number;
};

const TAX_LT20 = 12000;
const TAX_20_50 = 18000;

const CITIES: CityPrices[] = [
  { code: 'YIW', city: 'Yiwu', registration: 500, consulting: 3000, accountantNoTax: 3600, workResidence: 2500 },
  { code: 'FOS', city: 'Foshan', registration: 500, consulting: 3000, accountantNoTax: 3600, workResidence: 2500 },
  { code: 'SHA', city: 'Shanghai', registration: 500, consulting: 3000, accountantNoTax: 3600, workResidence: 2500 },
  { code: 'HIN', city: 'Hainan', registration: 500, consulting: 3000, accountantNoTax: 3600, workResidence: 2500 },
  { code: 'HZH', city: 'Hangzhou', registration: 500, consulting: 3000, accountantNoTax: 3600, workResidence: 2500 },
  { code: 'GZH', city: 'Guangzhou', registration: 1000, consulting: 3000, accountantNoTax: 4600, workResidence: 3500 },
  { code: 'SZX', city: 'Shenzhen', registration: 1000, consulting: 3000, accountantNoTax: 4600, workResidence: 3500 },
  { code: 'BJS', city: 'Beijing', registration: 1000, consulting: 4000, accountantNoTax: 4600, workResidence: 3500 },
];

const VERSION = 'boss-2026-10-v1';
const SOURCE = 'Boss Final Developer Execution Package v1.0 (Oct 2026), provisional price matrix';

export class PriceVersions1765840000000 implements MigrationInterface {
  name = 'PriceVersions1765840000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "price_versions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "price_id" varchar(64) NOT NULL,
        "version" varchar(32) NOT NULL,
        "service_key" varchar(80) NOT NULL,
        "item_name" varchar(160) NOT NULL,
        "city" varchar(60),
        "nationality" varchar(80),
        "obic_fee_cents" integer NOT NULL DEFAULT 0,
        "external_fee_cents" integer NOT NULL DEFAULT 0,
        "currency" varchar(8) NOT NULL DEFAULT 'CNY',
        "pricing_basis" varchar(40) NOT NULL DEFAULT 'per_order',
        "status" varchar(16) NOT NULL DEFAULT 'Draft',
        "effective_from" date,
        "effective_to" date,
        "approved_by" uuid,
        "source_ref" varchar(200),
        "note" varchar(500),
        "created_by" uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_price_versions" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_price_versions_price_version" UNIQUE ("price_id", "version"),
        CONSTRAINT "CHK_price_versions_status"
          CHECK ("status" IN ('Draft','Review','Approved','Active','Retired')),
        CONSTRAINT "CHK_price_versions_fees"
          CHECK ("obic_fee_cents" >= 0 AND "external_fee_cents" >= 0)
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_price_versions_service_city_status"
      ON "price_versions" ("service_key", "city", "status")
    `);

    for (const c of CITIES) {
      const items: Array<[string, string, number, string]> = [
        [`PRICE-${c.code}-REG`, 'OBIC company-registration preparation/follow-up service fee', c.registration, 'per_order'],
        [`PRICE-${c.code}-CONSULT`, 'Company formation consultation (mandatory)', c.consulting, 'per_order'],
        [`PRICE-${c.code}-ACC-NOTAX`, 'General accountant — without tax refund filing', c.accountantNoTax, 'per_year'],
        [`PRICE-${c.code}-ACC-TAX-LT20`, 'General accountant — tax refund filing, fewer than 20 cases/year', TAX_LT20, 'per_year'],
        [`PRICE-${c.code}-ACC-TAX-20-50`, 'General accountant — tax refund filing, more than 20 and fewer than 50 cases/year', TAX_20_50, 'per_year'],
        [`PRICE-${c.code}-WORKRES`, 'Work/residence application service', c.workResidence, 'per_order'],
      ];
      for (const [priceId, itemName, yuan, basis] of items) {
        await queryRunner.query(
          `
          INSERT INTO "price_versions"
            ("price_id", "version", "service_key", "item_name", "city",
             "obic_fee_cents", "external_fee_cents", "currency", "pricing_basis",
             "status", "source_ref")
          VALUES ($1, $2, 'company-registration', $3, $4, $5, 0, 'CNY', $6,
                  'Draft', $7)
          ON CONFLICT ("price_id", "version") DO NOTHING
          `,
          [priceId, VERSION, itemName, c.city, yuan * 100, basis, SOURCE],
        );
      }
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "price_versions"`);
  }
}
