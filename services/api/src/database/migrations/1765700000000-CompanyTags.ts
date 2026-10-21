// Made by Dr Ali
// Company tags and the contacts that carry them. Tags are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyTags1765700000000 implements MigrationInterface {
  name = 'CompanyTags1765700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_tags" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" varchar(24) NOT NULL,
        "name_key" varchar(24) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_tags" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_company_tags_name_key" UNIQUE ("name_key")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_contact_tags" (
        "contact_id" uuid NOT NULL,
        "tag_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_contact_tags" PRIMARY KEY ("contact_id", "tag_id"),
        CONSTRAINT "FK_company_contact_tags_contact"
          FOREIGN KEY ("contact_id") REFERENCES "company_contacts"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_company_contact_tags_tag"
          FOREIGN KEY ("tag_id") REFERENCES "company_tags"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_contact_tags_tag"
      ON "company_contact_tags" ("tag_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_contact_tags"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_tags"`);
  }
}
