// Made by Dr Ali
// Staff forms: a template of fields, then each submission keeps a copy of those fields.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class OfficeForms1765640000000 implements MigrationInterface {
  name = 'OfficeForms1765640000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "office_forms" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "name_en" varchar(120) NOT NULL,
        "name_ar" varchar(120) NOT NULL,
        "name_zh" varchar(120) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_office_forms" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "office_form_fields" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "form_id" uuid NOT NULL,
        "position" integer NOT NULL,
        "field_key" varchar(32) NOT NULL,
        "label_en" varchar(80) NOT NULL,
        "label_ar" varchar(80) NOT NULL,
        "label_zh" varchar(80) NOT NULL,
        "field_type" varchar(16) NOT NULL,
        "required" boolean NOT NULL DEFAULT false,
        "options" jsonb NOT NULL DEFAULT '[]',
        CONSTRAINT "PK_office_form_fields" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_office_form_fields_key" UNIQUE ("form_id", "field_key"),
        CONSTRAINT "UQ_office_form_fields_position" UNIQUE ("form_id", "position"),
        CONSTRAINT "CHK_office_form_fields_type"
          CHECK ("field_type" IN ('short_text', 'long_text', 'number', 'choice')),
        CONSTRAINT "FK_office_form_fields_form"
          FOREIGN KEY ("form_id") REFERENCES "office_forms"("id")
          ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "office_form_submissions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "form_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "answers" jsonb NOT NULL,
        "fields_snapshot" jsonb NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_office_form_submissions" PRIMARY KEY ("id"),
        CONSTRAINT "FK_office_form_submissions_form"
          FOREIGN KEY ("form_id") REFERENCES "office_forms"("id"),
        CONSTRAINT "FK_office_form_submissions_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_office_form_submissions_created"
        ON "office_form_submissions" ("created_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "office_form_submissions"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "office_form_fields"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "office_forms"`);
  }
}
