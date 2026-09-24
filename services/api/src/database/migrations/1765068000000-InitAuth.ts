// Made by Dr Ali
// Initial auth schema: users + refresh_sessions.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitAuth1765068000000 implements MigrationInterface {
  name = 'InitAuth1765068000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "users_role_enum" AS ENUM ('Customer', 'Employee', 'SuperAdmin')
    `);

    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "email" character varying(320),
        "phone" character varying(32),
        "password_hash" character varying(255) NOT NULL,
        "role" "users_role_enum" NOT NULL DEFAULT 'Customer',
        "name" character varying(120) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_users_email" UNIQUE ("email"),
        CONSTRAINT "UQ_users_phone" UNIQUE ("phone"),
        CONSTRAINT "PK_users" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "refresh_sessions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "token_hash" character varying(64) NOT NULL,
        "family_id" uuid NOT NULL,
        "expires_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "revoked_at" TIMESTAMP WITH TIME ZONE,
        "replaced_by_id" uuid,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_refresh_sessions_token_hash" UNIQUE ("token_hash"),
        CONSTRAINT "PK_refresh_sessions" PRIMARY KEY ("id"),
        CONSTRAINT "FK_refresh_sessions_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_refresh_sessions_user_id" ON "refresh_sessions" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_refresh_sessions_family_id" ON "refresh_sessions" ("family_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "refresh_sessions"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "users"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "users_role_enum"`);
  }
}
