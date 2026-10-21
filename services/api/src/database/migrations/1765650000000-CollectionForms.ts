// Made by Dr Ali
// One collection, the people it was sent to, and one answer row per person.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CollectionForms1765650000000 implements MigrationInterface {
  name = 'CollectionForms1765650000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "collection_forms" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "name_en" varchar(120) NOT NULL,
        "name_ar" varchar(120) NOT NULL,
        "name_zh" varchar(120) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_collection_forms" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "collection_form_fields" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "collection_id" uuid NOT NULL,
        "position" integer NOT NULL,
        "field_key" varchar(32) NOT NULL,
        "label_en" varchar(80) NOT NULL,
        "label_ar" varchar(80) NOT NULL,
        "label_zh" varchar(80) NOT NULL,
        "field_type" varchar(16) NOT NULL,
        "required" boolean NOT NULL DEFAULT false,
        "options" jsonb NOT NULL DEFAULT '[]',
        CONSTRAINT "PK_collection_form_fields" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_collection_form_fields_key"
          UNIQUE ("collection_id", "field_key"),
        CONSTRAINT "UQ_collection_form_fields_position"
          UNIQUE ("collection_id", "position"),
        CONSTRAINT "CHK_collection_form_fields_type"
          CHECK ("field_type" IN ('short_text', 'long_text', 'number', 'choice')),
        CONSTRAINT "FK_collection_form_fields_form"
          FOREIGN KEY ("collection_id") REFERENCES "collection_forms"("id")
          ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "collection_form_members" (
        "collection_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        CONSTRAINT "PK_collection_form_members" PRIMARY KEY ("collection_id", "user_id"),
        CONSTRAINT "FK_collection_form_members_form"
          FOREIGN KEY ("collection_id") REFERENCES "collection_forms"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_collection_form_members_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "collection_form_responses" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "collection_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "answers" jsonb NOT NULL,
        "fields_snapshot" jsonb NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_collection_form_responses" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_collection_form_responses_person"
          UNIQUE ("collection_id", "user_id"),
        CONSTRAINT "FK_collection_form_responses_form"
          FOREIGN KEY ("collection_id") REFERENCES "collection_forms"("id"),
        CONSTRAINT "FK_collection_form_responses_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "collection_form_responses"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "collection_form_members"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "collection_form_fields"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "collection_forms"`);
  }
}
