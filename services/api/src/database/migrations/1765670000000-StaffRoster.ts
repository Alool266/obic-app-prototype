// Made by Dr Ali
// One employment row per staff member.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class StaffRoster1765670000000 implements MigrationInterface {
  name = 'StaffRoster1765670000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "staff_employments" (
        "user_id" uuid NOT NULL,
        "joined_on" varchar(10) NOT NULL,
        "status" varchar(16) NOT NULL,
        "last_day" varchar(10),
        "leave_note" varchar(500),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_staff_employments" PRIMARY KEY ("user_id"),
        CONSTRAINT "CHK_staff_employments_status"
          CHECK ("status" IN ('active', 'leaving', 'left')),
        CONSTRAINT "CHK_staff_employments_joined"
          CHECK ("joined_on" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
        CONSTRAINT "CHK_staff_employments_last_day"
          CHECK ("last_day" IS NULL OR "last_day" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
        CONSTRAINT "FK_staff_employments_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "staff_employments"`);
  }
}
