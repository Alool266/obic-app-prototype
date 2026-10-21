// Made by Dr Ali
// Questions answered from shared company documents. Rows are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyFileAnswers1765810000000 implements MigrationInterface {
  name = 'CompanyFileAnswers1765810000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_file_answers" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "question" varchar(300) NOT NULL,
        "answer" varchar(2000) NOT NULL,
        "sources" jsonb NOT NULL DEFAULT '[]',
        "answered_by" varchar(12) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_file_answers" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_file_answers_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id"),
        CONSTRAINT "CHK_company_file_answers_by"
          CHECK ("answered_by" IN ('documents', 'ai'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_file_answers_user"
      ON "company_file_answers" ("user_id", "created_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_file_answers"`);
  }
}
