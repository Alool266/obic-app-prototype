// Made by Dr Ali
// Company greetings. One row may be the company default. Greetings are not deleted.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyWelcomes1765720000000 implements MigrationInterface {
  name = 'CompanyWelcomes1765720000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_welcomes" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "title" varchar(40) NOT NULL,
        "body" varchar(500) NOT NULL,
        "is_default" boolean NOT NULL DEFAULT false,
        "active" boolean NOT NULL DEFAULT true,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_welcomes" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_welcomes_default"
      ON "company_welcomes" ("is_default")
      WHERE "is_default" = true
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_welcome_assignments" (
        "user_id" uuid NOT NULL,
        "welcome_id" uuid NOT NULL,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_welcome_assignments" PRIMARY KEY ("user_id"),
        CONSTRAINT "FK_company_welcome_assignments_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id"),
        CONSTRAINT "FK_company_welcome_assignments_welcome"
          FOREIGN KEY ("welcome_id") REFERENCES "company_welcomes"("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_welcome_assignments"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_welcomes"`);
  }
}
