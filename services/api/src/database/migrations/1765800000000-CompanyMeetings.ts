// Made by Dr Ali
// Richer company meetings. Meetings are not deleted and do not start a call.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyMeetings1765800000000 implements MigrationInterface {
  name = 'CompanyMeetings1765800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_meetings" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(80) NOT NULL,
        "event_date" varchar(10) NOT NULL,
        "start_minute" integer NOT NULL,
        "end_minute" integer NOT NULL,
        "agenda" varchar(1000),
        "notes" varchar(2000),
        "active" boolean NOT NULL DEFAULT true,
        "created_by" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_meetings" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_meetings_created_by"
          FOREIGN KEY ("created_by") REFERENCES "users"("id"),
        CONSTRAINT "CHK_company_meetings_date"
          CHECK ("event_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
        CONSTRAINT "CHK_company_meetings_span"
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
      CREATE INDEX IF NOT EXISTS "IDX_company_meetings_date"
      ON "company_meetings" ("event_date")
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_meeting_attendees" (
        "meeting_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_meeting_attendees" PRIMARY KEY ("meeting_id", "user_id"),
        CONSTRAINT "FK_company_meeting_attendees_meeting"
          FOREIGN KEY ("meeting_id") REFERENCES "company_meetings"("id"),
        CONSTRAINT "FK_company_meeting_attendees_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_meeting_attendees_user"
      ON "company_meeting_attendees" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_meeting_attendees"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_meetings"`);
  }
}
