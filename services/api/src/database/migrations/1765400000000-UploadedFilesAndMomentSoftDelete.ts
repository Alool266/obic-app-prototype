// Made by Dr Ali
// Durable uploads (bytea) + soft-delete for Moments.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class UploadedFilesAndMomentSoftDelete1765400000000
  implements MigrationInterface
{
  name = 'UploadedFilesAndMomentSoftDelete1765400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "uploaded_files" (
        "id" uuid NOT NULL,
        "filename" character varying(255) NOT NULL,
        "original_name" character varying(512),
        "mime" character varying(128) NOT NULL,
        "size" integer NOT NULL,
        "data" bytea NOT NULL,
        "uploader_id" uuid,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_uploaded_files" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_uploaded_files_filename" UNIQUE ("filename")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "moments"
        ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_moments_deleted_at"
        ON "moments" ("deleted_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_moments_deleted_at"`);
    await queryRunner.query(`
      ALTER TABLE "moments" DROP COLUMN IF EXISTS "deleted_at"
    `);
    await queryRunner.query(`DROP TABLE IF EXISTS "uploaded_files"`);
  }
}
