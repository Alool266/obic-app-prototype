// Made by Dr Ali
// Company-owned customer contacts. A blank phone may repeat. A real phone may not.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyContacts1765690000000 implements MigrationInterface {
  name = 'CompanyContacts1765690000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_contacts" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "display_name" varchar(80) NOT NULL,
        "phone" varchar(21),
        "org_name" varchar(80),
        "note" varchar(500),
        "owner_user_id" uuid NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_contacts" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_contacts_owner"
          FOREIGN KEY ("owner_user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contacts_owner"
      ON "company_contacts" ("owner_user_id")
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_contacts_phone"
      ON "company_contacts" ("phone")
      WHERE "phone" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_contacts"`);
  }
}
