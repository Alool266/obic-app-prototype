// Made by Dr Ali
// Internal company mail. Messages are not deleted and are not sent outside OBIC.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyMail1765790000000 implements MigrationInterface {
  name = 'CompanyMail1765790000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_mail_messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "sender_user_id" uuid NOT NULL,
        "subject" varchar(80) NOT NULL,
        "body" varchar(2000) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_mail_messages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_mail_messages_sender"
          FOREIGN KEY ("sender_user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_mail_messages_sender"
      ON "company_mail_messages" ("sender_user_id")
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_mail_recipients" (
        "message_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "read_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_mail_recipients" PRIMARY KEY ("message_id", "user_id"),
        CONSTRAINT "FK_company_mail_recipients_message"
          FOREIGN KEY ("message_id") REFERENCES "company_mail_messages"("id"),
        CONSTRAINT "FK_company_mail_recipients_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_mail_recipients_user"
      ON "company_mail_recipients" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_mail_recipients"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_mail_messages"`);
  }
}
