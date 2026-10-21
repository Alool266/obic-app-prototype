// Made by Dr Ali
// Passport OCR extractions + three-way comparison + human decision queue
// (boss M04, TST-006). Behind OCR_ENABLED; the AI reads, humans decide,
// customer fields are never silently edited.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class DocumentExtractions1765860000000 implements MigrationInterface {
  name = 'DocumentExtractions1765860000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "document_extractions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "application_id" uuid NOT NULL,
        "document_id" uuid NOT NULL,
        "doc_type" varchar(32) NOT NULL,
        "doc_version" integer NOT NULL,
        "provider" varchar(40) NOT NULL,
        "model_version" varchar(120) NOT NULL,
        "extracted_fields" jsonb NOT NULL,
        "confidence" jsonb,
        "comparisons" jsonb NOT NULL,
        "has_mismatch" boolean NOT NULL DEFAULT false,
        "status" varchar(24) NOT NULL DEFAULT 'pending_review',
        "reviewed_by" uuid,
        "reviewed_at" TIMESTAMP WITH TIME ZONE,
        "review_note" text,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_document_extractions" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_document_extractions_status"
          CHECK ("status" IN ('pending_review','confirmed','rejected','superseded'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_document_extractions_app"
      ON "document_extractions" ("application_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_document_extractions_status"
      ON "document_extractions" ("status")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "document_extractions"`);
  }
}
