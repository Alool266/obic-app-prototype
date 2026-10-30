// Made by Dr Ali
// Company calendar events. Events are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyCalendar1765780000000 implements MigrationInterface {
  name = 'CompanyCalendar1765780000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_calendar_events" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(80) NOT NULL,
        "event_date" varchar(10) NOT NULL,
        "start_minute" integer NOT NULL,
        "end_minute" integer NOT NULL,
        "note" varchar(500),
        "active" boolean NOT NULL DEFAULT true,
        "created_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_calendar_events" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_calendar_events_created_by"
          FOREIGN KEY ("created_by") REFERENCES "users"("id"),
        CONSTRAINT "CHK_company_calendar_events_date"
          CHECK ("event_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
        CONSTRAINT "CHK_company_calendar_events_span"
          CHECK (
            "start_minute" >= 0
            AND "end_minute" <= 1439
            AND "end_minute" > "start_minute"
            AND ("end_minute" - "start_minute") >= 15
            AND ("end_minute" - "start_minute") <= 720
          )
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_calendar_events_date"
      ON "company_calendar_events" ("event_date")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_calendar_events"`);
  }
}
