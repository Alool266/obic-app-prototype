// Made by Dr Ali
// Non-VIP Company Registration (boss W1): applications with the 10-state
// machine + ContractID/TrackingID + frozen price snapshot, checklist
// documents with version history, timeline events, and the versioned
// eligibility-rule matrix (Draft → Review → Approved → Active → Retired).
// No seed rules are inserted: eligibility rows must be human-approved first
// (boss §6 — IT must not hard-code unverified city/legal rules).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class RegistrationApplications1765850000000 implements MigrationInterface {
  name = 'RegistrationApplications1765850000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "registration_applications" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "tracking_id" varchar(32) NOT NULL,
        "contract_id" varchar(32),
        "city" varchar(60) NOT NULL,
        "area" varchar(80),
        "nationality" varchar(80),
        "inside_china" boolean NOT NULL DEFAULT false,
        "qualification" varchar(120),
        "activity" varchar(120) NOT NULL,
        "eligibility_outcome" varchar(24) NOT NULL DEFAULT 'to_be_verified',
        "eligibility_rule_version" varchar(32),
        "eligibility_reason" text,
        "accountant_tier" varchar(16),
        "include_work_residence" boolean NOT NULL DEFAULT false,
        "status" varchar(24) NOT NULL DEFAULT 'DRAFT',
        "price_snapshot" jsonb,
        "form_data" jsonb,
        "assigned_employee_id" uuid,
        "submitted_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_registration_applications" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_registration_applications_tracking" UNIQUE ("tracking_id"),
        CONSTRAINT "CHK_registration_applications_status"
          CHECK ("status" IN ('DRAFT','SUBMITTED','PENDING_DOCUMENTS','UNDER_REVIEW','NEEDS_CUSTOMER_ACTION','APPROVED','REJECTED','IN_PROGRESS','COMPLETED','CANCELLED')),
        CONSTRAINT "CHK_registration_applications_eligibility"
          CHECK ("eligibility_outcome" IN ('eligible','ineligible','to_be_verified')),
        CONSTRAINT "CHK_registration_applications_tier"
          CHECK ("accountant_tier" IS NULL OR "accountant_tier" IN ('no_tax','tax_lt20','tax_20_50'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_registration_applications_user"
      ON "registration_applications" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_registration_applications_status"
      ON "registration_applications" ("status")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "registration_documents" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "application_id" uuid NOT NULL REFERENCES "registration_applications"("id") ON DELETE CASCADE,
        "doc_type" varchar(32) NOT NULL,
        "label" varchar(120) NOT NULL,
        "required" boolean NOT NULL DEFAULT true,
        "status" varchar(24) NOT NULL DEFAULT 'missing',
        "file_url" varchar(1024),
        "file_name" varchar(255),
        "version" integer NOT NULL DEFAULT 0,
        "review_note" text,
        "reviewed_by" uuid,
        "reviewed_at" TIMESTAMP WITH TIME ZONE,
        "history" jsonb,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_registration_documents" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_registration_documents_app_type" UNIQUE ("application_id", "doc_type"),
        CONSTRAINT "CHK_registration_documents_status"
          CHECK ("status" IN ('missing','pending','approved','correction_requested','blocked'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_registration_documents_app"
      ON "registration_documents" ("application_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "registration_events" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "application_id" uuid NOT NULL,
        "actor_id" uuid,
        "actor_type" varchar(16) NOT NULL,
        "action" varchar(60) NOT NULL,
        "from_status" varchar(24),
        "to_status" varchar(24),
        "field" varchar(60),
        "note" text,
        "delay_party" varchar(16),
        "meta" jsonb,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_registration_events" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_registration_events_app"
      ON "registration_events" ("application_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "eligibility_rules" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "version" varchar(32) NOT NULL,
        "city" varchar(60) NOT NULL,
        "activity" varchar(120) NOT NULL,
        "nationality" varchar(80),
        "inside_china" boolean,
        "outcome" varchar(16) NOT NULL,
        "reason" text,
        "alternative_cities" jsonb,
        "status" varchar(16) NOT NULL DEFAULT 'Draft',
        "effective_from" date,
        "effective_to" date,
        "approved_by" uuid,
        "source_ref" varchar(200),
        "created_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_eligibility_rules" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_eligibility_rules_city_activity_version" UNIQUE ("city", "activity", "version"),
        CONSTRAINT "CHK_eligibility_rules_status"
          CHECK ("status" IN ('Draft','Review','Approved','Active','Retired')),
        CONSTRAINT "CHK_eligibility_rules_outcome"
          CHECK ("outcome" IN ('eligible','ineligible'))
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "eligibility_rules"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "registration_events"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "registration_documents"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "registration_applications"`);
  }
}
