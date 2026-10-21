// Made by Dr Ali
// Customer handover history. Contacts are moved, not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyHandovers1765740000000 implements MigrationInterface {
  name = 'CompanyHandovers1765740000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_contact_handovers" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "from_user_id" uuid NOT NULL,
        "to_user_id" uuid NOT NULL,
        "actor_user_id" uuid NOT NULL,
        "contact_count" integer NOT NULL,
        "contacts" jsonb NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_contact_handovers" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_contact_handovers_from"
          FOREIGN KEY ("from_user_id") REFERENCES "users"("id"),
        CONSTRAINT "FK_company_contact_handovers_to"
          FOREIGN KEY ("to_user_id") REFERENCES "users"("id"),
        CONSTRAINT "FK_company_contact_handovers_actor"
          FOREIGN KEY ("actor_user_id") REFERENCES "users"("id"),
        CONSTRAINT "CHK_company_contact_handovers_count"
          CHECK ("contact_count" >= 1 AND "contact_count" <= 200),
        CONSTRAINT "CHK_company_contact_handovers_parties"
          CHECK ("from_user_id" <> "to_user_id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contact_handovers_from"
      ON "company_contact_handovers" ("from_user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contact_handovers_to"
      ON "company_contact_handovers" ("to_user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_contact_handovers"`);
  }
}
