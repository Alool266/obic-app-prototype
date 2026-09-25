// Made by Dr Ali
// emailVerifiedAt / phoneVerifiedAt + verification_challenges table.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserVerification1765460000000 implements MigrationInterface {
  name = 'UserVerification1765460000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "email_verified_at" TIMESTAMPTZ NULL,
        ADD COLUMN IF NOT EXISTS "phone_verified_at" TIMESTAMPTZ NULL
    `);
    // Grandfather existing accounts as verified.
    await queryRunner.query(`
      UPDATE "users"
      SET "email_verified_at" = COALESCE("email_verified_at", "created_at")
      WHERE "email" IS NOT NULL AND "email_verified_at" IS NULL
    `);
    await queryRunner.query(`
      UPDATE "users"
      SET "phone_verified_at" = COALESCE("phone_verified_at", "created_at")
      WHERE "phone" IS NOT NULL AND "phone_verified_at" IS NULL
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "verification_challenges" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "channel" varchar(16) NOT NULL,
        "purpose" varchar(24) NOT NULL,
        "destination" varchar(320) NOT NULL,
        "code_hash" varchar(128) NOT NULL,
        "expires_at" TIMESTAMPTZ NOT NULL,
        "last_sent_at" TIMESTAMPTZ NOT NULL,
        "attempts" int NOT NULL DEFAULT 0,
        "pending_value" varchar(320) NULL,
        "debug_code" varchar(12) NULL,
        "delivery" varchar(32) NOT NULL DEFAULT 'unknown',
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_verification_challenges" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_verification_challenges_user"
        ON "verification_challenges" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "verification_challenges"`);
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "phone_verified_at",
        DROP COLUMN IF EXISTS "email_verified_at"
    `);
  }
}
