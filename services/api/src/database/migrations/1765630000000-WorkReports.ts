// Made by Dr Ali
// Daily, weekly, and monthly work reports, plus the people who receive them.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class WorkReports1765630000000 implements MigrationInterface {
  name = 'WorkReports1765630000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "work_report_settings" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "timezone" varchar(64) NOT NULL,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_work_report_settings" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      INSERT INTO "work_report_settings" ("id", "timezone")
      VALUES ('6f0e2a10-0003-4000-8000-000000000001', 'Asia/Shanghai')
      ON CONFLICT ("id") DO NOTHING
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "work_report_reviewers" (
        "user_id" uuid NOT NULL,
        "setting_id" uuid NOT NULL,
        "position" integer NOT NULL,
        CONSTRAINT "PK_work_report_reviewers" PRIMARY KEY ("user_id"),
        CONSTRAINT "FK_work_report_reviewers_setting"
          FOREIGN KEY ("setting_id") REFERENCES "work_report_settings"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_work_report_reviewers_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "work_reports" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "kind" varchar(16) NOT NULL,
        "period_key" varchar(16) NOT NULL,
        "done" varchar(2000) NOT NULL,
        "plan" varchar(2000) NOT NULL,
        "blockers" varchar(1000) NOT NULL DEFAULT '',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_work_reports" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_work_reports_period"
          UNIQUE ("user_id", "kind", "period_key"),
        CONSTRAINT "CHK_work_reports_kind"
          CHECK ("kind" IN ('daily', 'weekly', 'monthly')),
        CONSTRAINT "FK_work_reports_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_work_reports_updated"
        ON "work_reports" ("updated_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "work_reports"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "work_report_reviewers"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "work_report_settings"`);
  }
}
