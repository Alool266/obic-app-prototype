// Made by Dr Ali
// Moment likes + comments tables.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class MomentLikesComments1765100000000 implements MigrationInterface {
  name = 'MomentLikesComments1765100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "moment_likes" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "moment_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moment_likes" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_moment_likes_moment_user" UNIQUE ("moment_id", "user_id"),
        CONSTRAINT "FK_moment_likes_moment"
          FOREIGN KEY ("moment_id") REFERENCES "moments"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_moment_likes_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_moment_likes_moment" ON "moment_likes" ("moment_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "moment_comments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "moment_id" uuid NOT NULL,
        "author_id" uuid NOT NULL,
        "body" character varying(500) NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moment_comments" PRIMARY KEY ("id"),
        CONSTRAINT "FK_moment_comments_moment"
          FOREIGN KEY ("moment_id") REFERENCES "moments"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_moment_comments_author"
          FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_moment_comments_moment" ON "moment_comments" ("moment_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "moment_comments"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "moment_likes"`);
  }
}
