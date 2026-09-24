// Made by Dr Ali
// Phase 5 deepen — assistant history tables + app_settings for global AI toggle.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Phase5AiDeepen1765420000000 implements MigrationInterface {
  name = 'Phase5AiDeepen1765420000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "ai_assistant_threads" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "title" character varying(120) NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ai_assistant_threads" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_ai_assistant_threads_user_id"
        ON "ai_assistant_threads" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_ai_assistant_threads_user_updated"
        ON "ai_assistant_threads" ("user_id", "updated_at" DESC)
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "ai_assistant_messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "thread_id" uuid NOT NULL,
        "role" character varying(16) NOT NULL,
        "content" text NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ai_assistant_messages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_ai_assistant_messages_thread"
          FOREIGN KEY ("thread_id") REFERENCES "ai_assistant_threads"("id")
          ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_ai_assistant_messages_thread_id"
        ON "ai_assistant_messages" ("thread_id")
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "app_settings" (
        "key" character varying(80) NOT NULL,
        "value" text NOT NULL,
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_app_settings" PRIMARY KEY ("key")
      )
    `);
    await queryRunner.query(`
      INSERT INTO "app_settings" ("key", "value")
      VALUES ('ai_auto_reply_global', 'true')
      ON CONFLICT ("key") DO NOTHING
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "ai_assistant_messages"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "ai_assistant_threads"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "app_settings"`);
  }
}
