// Made by Dr Ali
// Shared company documents. Documents are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyDocuments1765760000000 implements MigrationInterface {
  name = 'CompanyDocuments1765760000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_documents" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(80) NOT NULL,
        "title_key" varchar(80) NOT NULL,
        "body" varchar(8000) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "updated_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_documents" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_documents_updated_by"
          FOREIGN KEY ("updated_by") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_documents_title"
      ON "company_documents" ("title_key")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_documents"`);
  }
}
