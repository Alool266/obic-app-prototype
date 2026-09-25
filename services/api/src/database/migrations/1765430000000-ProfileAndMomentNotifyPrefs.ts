// Made by Dr Ali
// Profile city/country + server Moments notify prefs (global + per-friend mute).

import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProfileAndMomentNotifyPrefs1765430000000
  implements MigrationInterface
{
  name = 'ProfileAndMomentNotifyPrefs1765430000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "city" varchar(120) NULL,
        ADD COLUMN IF NOT EXISTS "country" varchar(120) NULL
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "moment_notify_prefs" (
        "user_id" uuid NOT NULL,
        "notify_enabled" boolean NOT NULL DEFAULT true,
        "mute_updates" boolean NOT NULL DEFAULT false,
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moment_notify_prefs" PRIMARY KEY ("user_id"),
        CONSTRAINT "FK_moment_notify_prefs_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "moment_friend_mutes" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "muted_friend_id" uuid NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moment_friend_mutes" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_moment_friend_mutes_pair" UNIQUE ("user_id", "muted_friend_id"),
        CONSTRAINT "FK_moment_friend_mutes_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_moment_friend_mutes_friend"
          FOREIGN KEY ("muted_friend_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_moment_friend_mutes_user"
        ON "moment_friend_mutes" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "moment_friend_mutes"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "moment_notify_prefs"`);
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN IF EXISTS "country",
        DROP COLUMN IF EXISTS "city"
    `);
  }
}
