// Made by Dr Ali
// Phones registered for Apple Push and Firebase Cloud Messaging.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class PushDevices1765830000000 implements MigrationInterface {
  name = 'PushDevices1765830000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "push_devices" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "platform" varchar(16) NOT NULL,
        "token" varchar(512) NOT NULL,
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_push_devices" PRIMARY KEY ("id"),
        CONSTRAINT "FK_push_devices_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "UQ_push_devices_token" UNIQUE ("token")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_push_devices_user"
        ON "push_devices" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "push_devices"`);
  }
}
