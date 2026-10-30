// Made by Dr Ali
// Company web tools. Rows are paused, not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyApps1765820000000 implements MigrationInterface {
  name = 'CompanyApps1765820000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_apps" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" varchar(40) NOT NULL,
        "name_key" varchar(40) NOT NULL,
        "note" varchar(300),
        "url" varchar(200) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_apps" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_company_apps_name" UNIQUE ("name_key"),
        CONSTRAINT "FK_company_apps_created_by"
          FOREIGN KEY ("created_by") REFERENCES "users"("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_apps"`);
  }
}
