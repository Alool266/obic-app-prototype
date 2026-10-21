// Made by Dr Ali
// Sequential approvals: a template, then a request that walks its approvers.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Approvals1765610000000 implements MigrationInterface {
  name = 'Approvals1765610000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "approval_templates" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "name_en" varchar(120) NOT NULL,
        "name_ar" varchar(120) NOT NULL,
        "name_zh" varchar(120) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_approval_templates" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "approval_template_steps" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "template_id" uuid NOT NULL,
        "position" integer NOT NULL,
        "approver_user_id" uuid NOT NULL,
        CONSTRAINT "PK_approval_template_steps" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_approval_template_steps_position"
          UNIQUE ("template_id", "position"),
        CONSTRAINT "FK_approval_template_steps_template"
          FOREIGN KEY ("template_id") REFERENCES "approval_templates"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_approval_template_steps_user"
          FOREIGN KEY ("approver_user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "approval_requests" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "template_id" uuid NOT NULL,
        "requester_id" uuid NOT NULL,
        "title" varchar(160) NOT NULL,
        "body" varchar(2000) NOT NULL DEFAULT '',
        "status" varchar(16) NOT NULL DEFAULT 'pending',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_approval_requests" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_approval_requests_status"
          CHECK ("status" IN ('pending', 'approved', 'rejected', 'cancelled')),
        CONSTRAINT "FK_approval_requests_template"
          FOREIGN KEY ("template_id") REFERENCES "approval_templates"("id"),
        CONSTRAINT "FK_approval_requests_requester"
          FOREIGN KEY ("requester_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "approval_request_steps" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "request_id" uuid NOT NULL,
        "position" integer NOT NULL,
        "approver_user_id" uuid NOT NULL,
        "status" varchar(16) NOT NULL,
        "comment" varchar(500),
        "decided_at" TIMESTAMP WITH TIME ZONE,
        "decided_by_user_id" uuid,
        CONSTRAINT "PK_approval_request_steps" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_approval_request_steps_position"
          UNIQUE ("request_id", "position"),
        CONSTRAINT "CHK_approval_request_steps_status"
          CHECK ("status" IN ('waiting', 'pending', 'approved', 'rejected')),
        CONSTRAINT "FK_approval_request_steps_request"
          FOREIGN KEY ("request_id") REFERENCES "approval_requests"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_approval_request_steps_user"
          FOREIGN KEY ("approver_user_id") REFERENCES "users"("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "approval_request_steps"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "approval_requests"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "approval_template_steps"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "approval_templates"`);
  }
}
