// Made by Dr Ali
// Company and personal quick replies. Replies are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class QuickReplies1765730000000 implements MigrationInterface {
  name = 'QuickReplies1765730000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_quick_replies" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(24) NOT NULL,
        "title_key" varchar(24) NOT NULL,
        "body" varchar(300) NOT NULL,
        "owner_user_id" uuid,
        "active" boolean NOT NULL DEFAULT true,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_quick_replies" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_quick_replies_owner"
          FOREIGN KEY ("owner_user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_quick_replies_company_title"
      ON "company_quick_replies" ("title_key")
      WHERE "owner_user_id" IS NULL
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_quick_replies_owner_title"
      ON "company_quick_replies" ("owner_user_id", "title_key")
      WHERE "owner_user_id" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_quick_replies"`);
  }
}
