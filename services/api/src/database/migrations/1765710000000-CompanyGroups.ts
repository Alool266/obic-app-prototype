// Made by Dr Ali
// Named sets of company contacts. Groups are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyGroups1765710000000 implements MigrationInterface {
  name = 'CompanyGroups1765710000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_contact_groups" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" varchar(40) NOT NULL,
        "name_key" varchar(40) NOT NULL,
        "note" varchar(200),
        "owner_user_id" uuid NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_contact_groups" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_company_contact_groups_owner_name" UNIQUE ("owner_user_id", "name_key"),
        CONSTRAINT "FK_company_contact_groups_owner"
          FOREIGN KEY ("owner_user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contact_groups_owner"
      ON "company_contact_groups" ("owner_user_id")
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_contact_group_members" (
        "group_id" uuid NOT NULL,
        "contact_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_contact_group_members" PRIMARY KEY ("group_id", "contact_id"),
        CONSTRAINT "FK_company_contact_group_members_group"
          FOREIGN KEY ("group_id") REFERENCES "company_contact_groups"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_company_contact_group_members_contact"
          FOREIGN KEY ("contact_id") REFERENCES "company_contacts"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contact_group_members_contact"
      ON "company_contact_group_members" ("contact_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_contact_group_members"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_contact_groups"`);
  }
}
