// Made by Dr Ali
// Per-user Channels + official role gate + likes/comments/shares.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class PerUserChannelsAndEngagement1765540000000
  implements MigrationInterface
{
  name = 'PerUserChannelsAndEngagement1765540000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "channels"
        ADD COLUMN IF NOT EXISTS "owner_user_id" uuid NULL
          REFERENCES "users"("id") ON DELETE CASCADE
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_channels_owner_user"
        ON "channels" ("owner_user_id")
        WHERE "owner_user_id" IS NOT NULL
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_channels_official"
        ON "channels" ("official")
    `);

    await queryRunner.query(`
      ALTER TABLE "channel_videos"
        ADD COLUMN IF NOT EXISTS "like_count" integer NOT NULL DEFAULT 0
    `);
    await queryRunner.query(`
      ALTER TABLE "channel_videos"
        ADD COLUMN IF NOT EXISTS "comment_count" integer NOT NULL DEFAULT 0
    `);
    await queryRunner.query(`
      ALTER TABLE "channel_videos"
        ADD COLUMN IF NOT EXISTS "share_count" integer NOT NULL DEFAULT 0
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "channel_video_likes" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "video_id" uuid NOT NULL REFERENCES "channel_videos"("id") ON DELETE CASCADE,
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE ("video_id", "user_id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_channel_video_likes_user"
        ON "channel_video_likes" ("user_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "channel_video_comments" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "video_id" uuid NOT NULL REFERENCES "channel_videos"("id") ON DELETE CASCADE,
        "author_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "body" varchar(500) NOT NULL DEFAULT '',
        "deleted_at" TIMESTAMPTZ NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_channel_video_comments_video"
        ON "channel_video_comments" ("video_id", "created_at" DESC)
        WHERE "deleted_at" IS NULL
    `);

    // Ensure official OBIC channel exists and is not owner-bound.
    await queryRunner.query(`
      INSERT INTO "channels" ("slug", "name", "description", "official")
      SELECT 'obic', 'OBIC Official Channel',
             'Short videos from OBIC staff', true
      WHERE NOT EXISTS (SELECT 1 FROM "channels" WHERE "slug" = 'obic')
    `);
    await queryRunner.query(`
      UPDATE "channels"
      SET "name" = 'OBIC Official Channel',
          "description" = COALESCE("description", 'Short videos from OBIC staff'),
          "official" = true,
          "owner_user_id" = NULL
      WHERE "slug" = 'obic'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "channel_video_comments"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "channel_video_likes"`);
    await queryRunner.query(`
      ALTER TABLE "channel_videos" DROP COLUMN IF EXISTS "share_count"
    `);
    await queryRunner.query(`
      ALTER TABLE "channel_videos" DROP COLUMN IF EXISTS "comment_count"
    `);
    await queryRunner.query(`
      ALTER TABLE "channel_videos" DROP COLUMN IF EXISTS "like_count"
    `);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_channels_official"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_channels_owner_user"`);
    await queryRunner.query(`
      ALTER TABLE "channels" DROP COLUMN IF EXISTS "owner_user_id"
    `);
  }
}
