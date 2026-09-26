// Made by Dr Ali
// WeChat Moments privacy: partial/exclude lists + per-friend hide-from.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentPrivacyAcl1765500000000 implements MigrationInterface {
  name = 'MomentPrivacyAcl1765500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "moments"
        ADD COLUMN IF NOT EXISTS "allowed_user_ids" jsonb NOT NULL DEFAULT '[]'::jsonb
    `);
    await queryRunner.query(`
      ALTER TABLE "moments"
        ADD COLUMN IF NOT EXISTS "denied_user_ids" jsonb NOT NULL DEFAULT '[]'::jsonb
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "moment_friend_hides" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "hidden_from_friend_id" uuid NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moment_friend_hides" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_moment_friend_hides_pair" UNIQUE ("user_id", "hidden_from_friend_id"),
        CONSTRAINT "FK_moment_friend_hides_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_moment_friend_hides_friend"
          FOREIGN KEY ("hidden_from_friend_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_moment_friend_hides_user"
        ON "moment_friend_hides" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_moment_friend_hides_friend"
        ON "moment_friend_hides" ("hidden_from_friend_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_moment_friend_hides_friend"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_moment_friend_hides_user"`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS "moment_friend_hides"`);
    await queryRunner.query(`
      ALTER TABLE "moments" DROP COLUMN IF EXISTS "denied_user_ids"
    `);
    await queryRunner.query(`
      ALTER TABLE "moments" DROP COLUMN IF EXISTS "allowed_user_ids"
    `);
  }
}
