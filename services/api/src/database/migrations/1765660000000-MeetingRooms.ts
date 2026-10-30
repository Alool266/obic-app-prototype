// Made by Dr Ali
// Meeting rooms and the bookings that must not overlap inside one room.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MeetingRooms1765660000000 implements MigrationInterface {
  name = 'MeetingRooms1765660000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "meeting_rooms" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "name_en" varchar(120) NOT NULL,
        "name_ar" varchar(120) NOT NULL,
        "name_zh" varchar(120) NOT NULL,
        "branch_label" varchar(120),
        "capacity" integer NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_meeting_rooms" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_meeting_rooms_capacity"
          CHECK ("capacity" >= 1 AND "capacity" <= 200)
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "meeting_bookings" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "room_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "title" varchar(120) NOT NULL,
        "starts_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "ends_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "status" varchar(16) NOT NULL DEFAULT 'booked',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_meeting_bookings" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_meeting_bookings_status"
          CHECK ("status" IN ('booked', 'cancelled')),
        CONSTRAINT "CHK_meeting_bookings_window"
          CHECK ("ends_at" > "starts_at"),
        CONSTRAINT "FK_meeting_bookings_room"
          FOREIGN KEY ("room_id") REFERENCES "meeting_rooms"("id"),
        CONSTRAINT "FK_meeting_bookings_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_meeting_bookings_room_window"
        ON "meeting_bookings" ("room_id", "starts_at", "ends_at")
        WHERE "status" = 'booked'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "meeting_bookings"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "meeting_rooms"`);
  }
}
