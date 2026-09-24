// Made by Dr Ali
// Avatars on users + multi media (image/video/file) on moments.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentsMediaAvatars1765090000000 implements MigrationInterface {
  name = 'MomentsMediaAvatars1765090000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "avatar_url" character varying(1024)
    `);

    await queryRunner.query(`
      ALTER TABLE "moments"
      ADD COLUMN IF NOT EXISTS "media" jsonb NOT NULL DEFAULT '[]'::jsonb
    `);

    // Fold legacy single image_url into media array where present.
    await queryRunner.query(`
      UPDATE "moments"
      SET "media" = jsonb_build_array(
        jsonb_build_object(
          'kind', 'image',
          'url', "image_url",
          'name', 'photo.jpg'
        )
      )
      WHERE "image_url" IS NOT NULL
        AND "image_url" <> ''
        AND (jsonb_array_length("media") = 0 OR "media" IS NULL)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "moments" DROP COLUMN IF EXISTS "media"`);
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN IF EXISTS "avatar_url"`,
    );
  }
}
