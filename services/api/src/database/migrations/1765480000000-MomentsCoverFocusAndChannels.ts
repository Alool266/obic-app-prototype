// Made by Dr Ali
// Moments cover vertical focus + OBIC Channels (视频号) tables.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentsCoverFocusAndChannels1765480000000
  implements MigrationInterface
{
  name = 'MomentsCoverFocusAndChannels1765480000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "moments_cover_focus_y" double precision NOT NULL DEFAULT 0
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "channels" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "slug" varchar(64) NOT NULL UNIQUE,
        "name" varchar(120) NOT NULL,
        "description" varchar(1024) NULL,
        "avatar_url" varchar(1024) NULL,
        "cover_url" varchar(1024) NULL,
        "official" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "channel_follows" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "channel_id" uuid NOT NULL REFERENCES "channels"("id") ON DELETE CASCADE,
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE ("channel_id", "user_id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_channel_follows_user"
        ON "channel_follows" ("user_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "channel_videos" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "channel_id" uuid NOT NULL REFERENCES "channels"("id") ON DELETE CASCADE,
        "author_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "video_url" varchar(1024) NOT NULL,
        "thumb_url" varchar(1024) NULL,
        "caption" varchar(500) NOT NULL DEFAULT '',
        "duration_sec" integer NULL,
        "byte_size" integer NULL,
        "deleted_at" TIMESTAMPTZ NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_channel_videos_feed"
        ON "channel_videos" ("channel_id", "created_at" DESC)
        WHERE "deleted_at" IS NULL
    `);

    await queryRunner.query(`
      INSERT INTO "channels" ("slug", "name", "description", "official")
      SELECT 'obic', 'OBIC Channel', 'Short videos from OBIC and the community', true
      WHERE NOT EXISTS (SELECT 1 FROM "channels" WHERE "slug" = 'obic')
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "channel_videos"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "channel_follows"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "channels"`);
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "moments_cover_focus_y"
    `);
  }
}
