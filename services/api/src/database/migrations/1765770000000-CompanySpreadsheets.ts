// Made by Dr Ali
// Shared spreadsheets. Sheets are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanySpreadsheets1765770000000 implements MigrationInterface {
  name = 'CompanySpreadsheets1765770000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_spreadsheets" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(40) NOT NULL,
        "title_key" varchar(40) NOT NULL,
        "grid" jsonb NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "updated_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_spreadsheets" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_spreadsheets_updated_by"
          FOREIGN KEY ("updated_by") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_spreadsheets_title"
      ON "company_spreadsheets" ("title_key")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_spreadsheets"`);
  }
}
