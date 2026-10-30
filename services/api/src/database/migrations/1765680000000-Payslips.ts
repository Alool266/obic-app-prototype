// Made by Dr Ali
// Monthly staff payslips. Amounts are stored in cents. No money is sent.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Payslips1765680000000 implements MigrationInterface {
  name = 'Payslips1765680000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "staff_payslips" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "period_key" varchar(7) NOT NULL,
        "currency" varchar(8) NOT NULL DEFAULT 'CNY',
        "note" varchar(500),
        "lines" jsonb NOT NULL,
        "net_cents" integer NOT NULL,
        "acknowledged_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_staff_payslips" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_staff_payslips_user_period" UNIQUE ("user_id", "period_key"),
        CONSTRAINT "CHK_staff_payslips_period"
          CHECK ("period_key" ~ '^[0-9]{4}-[0-9]{2}$'),
        CONSTRAINT "CHK_staff_payslips_currency" CHECK ("currency" = 'CNY'),
        CONSTRAINT "FK_staff_payslips_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_staff_payslips_period"
      ON "staff_payslips" ("period_key")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "staff_payslips"`);
  }
}
