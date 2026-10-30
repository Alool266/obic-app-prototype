// Made by Dr Ali
// Company clock: one rule, then one in and one out per person per company day.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Attendance1765620000000 implements MigrationInterface {
  name = 'Attendance1765620000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "attendance_rules" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "timezone" varchar(64) NOT NULL,
        "start_minute" integer NOT NULL,
        "end_minute" integer NOT NULL,
        "grace_minutes" integer NOT NULL DEFAULT 0,
        "weekdays" varchar(16) NOT NULL,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_attendance_rules" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_attendance_rules_minutes"
          CHECK (
            "start_minute" >= 0 AND "start_minute" <= 1439
            AND "end_minute" >= 0 AND "end_minute" <= 1439
            AND "start_minute" < "end_minute"
            AND "grace_minutes" >= 0 AND "grace_minutes" <= 180
          )
      )
    `);
    await queryRunner.query(`
      INSERT INTO "attendance_rules"
        ("id", "timezone", "start_minute", "end_minute", "grace_minutes", "weekdays")
      VALUES
        (
          '6f0e2a10-0002-4000-8000-000000000001',
          'Asia/Shanghai',
          540,
          1080,
          0,
          '1,2,3,4,5'
        )
      ON CONFLICT ("id") DO NOTHING
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "attendance_punches" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "work_date" date NOT NULL,
        "kind" varchar(8) NOT NULL,
        "punched_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "note" varchar(200),
        "mark" varchar(16) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_attendance_punches" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_attendance_punches_day"
          UNIQUE ("user_id", "work_date", "kind"),
        CONSTRAINT "CHK_attendance_punches_kind"
          CHECK ("kind" IN ('in', 'out')),
        CONSTRAINT "CHK_attendance_punches_mark"
          CHECK ("mark" IN ('on_time', 'late', 'early', 'off_day')),
        CONSTRAINT "FK_attendance_punches_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_attendance_punches_work_date"
        ON "attendance_punches" ("work_date")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "attendance_punches"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "attendance_rules"`);
  }
}
