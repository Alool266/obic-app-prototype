// Made by Dr Ali
// Company drive. Files are not deleted. Bytes stay off the public upload path.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class CompanyDrive1765750000000 implements MigrationInterface {
  name = 'CompanyDrive1765750000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_drive_folders" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" varchar(40) NOT NULL,
        "name_key" varchar(40) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_drive_folders" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_drive_folders_name"
      ON "company_drive_folders" ("name_key")
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "company_drive_files" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "folder_id" uuid NOT NULL,
        "name" varchar(80) NOT NULL,
        "name_key" varchar(80) NOT NULL,
        "ext" varchar(8) NOT NULL,
        "mime" varchar(128) NOT NULL,
        "size" integer NOT NULL,
        "data" bytea NOT NULL,
        "uploader_id" uuid NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_company_drive_files" PRIMARY KEY ("id"),
        CONSTRAINT "FK_company_drive_files_folder"
          FOREIGN KEY ("folder_id") REFERENCES "company_drive_folders"("id"),
        CONSTRAINT "FK_company_drive_files_uploader"
          FOREIGN KEY ("uploader_id") REFERENCES "users"("id"),
        CONSTRAINT "CHK_company_drive_files_size"
          CHECK ("size" >= 1 AND "size" <= 8388608)
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_company_drive_files_folder_name"
      ON "company_drive_files" ("folder_id", "name_key")
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_company_drive_files_folder"
      ON "company_drive_files" ("folder_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "company_drive_files"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "company_drive_folders"`);
  }
}
