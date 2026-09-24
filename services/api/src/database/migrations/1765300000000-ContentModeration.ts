// Made by Dr Ali
// Phase B: banned-word list + report queue. Seed is an initial set SuperAdmin can grow.

import { MigrationInterface, QueryRunner } from 'typeorm';

const SEED: Array<{ phrase: string; category: string }> = [
  { phrase: 'child porn', category: 'child_safety' },
  { phrase: 'child pornography', category: 'child_safety' },
  { phrase: 'underage sex', category: 'child_safety' },
  { phrase: 'استغلال الأطفال', category: 'child_safety' },
  { phrase: 'sell cocaine', category: 'drugs' },
  { phrase: 'sell heroin', category: 'drugs' },
  { phrase: 'كوكايين للبيع', category: 'drugs' },
  { phrase: 'هيروين', category: 'drugs' },
  { phrase: 'buy illegal gun', category: 'weapons' },
  { phrase: 'سلاح غير قانوني', category: 'weapons' },
  { phrase: 'make a bomb', category: 'terrorism' },
  { phrase: 'تنظيم إرهابي', category: 'terrorism' },
  { phrase: 'credit card dump', category: 'fraud' },
  { phrase: 'احتيال مالي', category: 'fraud' },
  { phrase: 'steal password', category: 'hacking' },
  { phrase: 'اختراق حساب', category: 'hacking' },
];

export class ContentModeration1765300000000 implements MigrationInterface {
  name = 'ContentModeration1765300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "content_reports_target_enum" AS ENUM (
        'message', 'moment', 'comment', 'thread'
      )
    `);
    await queryRunner.query(`
      CREATE TYPE "content_reports_source_enum" AS ENUM ('user', 'auto')
    `);
    await queryRunner.query(`
      CREATE TYPE "content_reports_status_enum" AS ENUM (
        'open', 'reviewed', 'dismissed'
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "banned_words" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "phrase" character varying(120) NOT NULL,
        "category" character varying(40) NOT NULL DEFAULT 'general',
        "is_active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_banned_words" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_banned_words_phrase" UNIQUE ("phrase")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "content_reports" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "reporter_id" uuid,
        "target_type" "content_reports_target_enum" NOT NULL,
        "target_id" uuid NOT NULL,
        "source" "content_reports_source_enum" NOT NULL DEFAULT 'user',
        "reason" character varying(500) NOT NULL DEFAULT '',
        "snippet" character varying(160) NOT NULL DEFAULT '',
        "status" "content_reports_status_enum" NOT NULL DEFAULT 'open',
        "reviewed_by" uuid,
        "reviewed_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_content_reports" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_content_reports_reporter" ON "content_reports" ("reporter_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_content_reports_status" ON "content_reports" ("status")`,
    );

    for (const row of SEED) {
      await queryRunner.query(
        `INSERT INTO "banned_words" ("phrase", "category") VALUES ($1, $2)
         ON CONFLICT ("phrase") DO NOTHING`,
        [row.phrase, row.category],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "content_reports"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "banned_words"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "content_reports_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "content_reports_source_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "content_reports_target_enum"`);
  }
}
