// Made by Dr Ali
// Phase 3: chat, moments, notifications, friendships + audit stub.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class Phase3Social1765080000000 implements MigrationInterface {
  name = 'Phase3Social1765080000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "conversations_kind_enum" AS ENUM ('direct', 'support')
    `);
    await queryRunner.query(`
      CREATE TABLE "conversations" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "kind" "conversations_kind_enum" NOT NULL DEFAULT 'direct',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_conversations" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "conversation_participants" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "conversation_id" uuid NOT NULL,
        "user_id" uuid NOT NULL,
        "last_read_at" TIMESTAMP WITH TIME ZONE,
        "joined_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_conversation_participants" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_conversation_participants_pair"
          UNIQUE ("conversation_id", "user_id"),
        CONSTRAINT "FK_cp_conversation"
          FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_cp_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_cp_user_id" ON "conversation_participants" ("user_id")
    `);

    await queryRunner.query(`
      CREATE TYPE "messages_attachment_kind_enum" AS ENUM ('none', 'image', 'file')
    `);
    await queryRunner.query(`
      CREATE TABLE "messages" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "conversation_id" uuid NOT NULL,
        "sender_id" uuid NOT NULL,
        "body" text NOT NULL DEFAULT '',
        "attachment_kind" "messages_attachment_kind_enum" NOT NULL DEFAULT 'none',
        "attachment_name" character varying(255),
        "attachment_url" character varying(1024),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_messages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_messages_conversation"
          FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id")
          ON DELETE CASCADE,
        CONSTRAINT "FK_messages_sender"
          FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_messages_conversation_id"
        ON "messages" ("conversation_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_messages_created_at" ON "messages" ("created_at")
    `);

    await queryRunner.query(`
      CREATE TABLE "moments" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "author_id" uuid NOT NULL,
        "body" text NOT NULL,
        "image_url" character varying(1024),
        "notify_all" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_moments" PRIMARY KEY ("id"),
        CONSTRAINT "FK_moments_author"
          FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_moments_created_at" ON "moments" ("created_at")
    `);

    await queryRunner.query(`
      CREATE TYPE "notifications_kind_enum" AS ENUM (
        'moment', 'friend_request', 'friend_accepted', 'message', 'system'
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "notifications" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "kind" "notifications_kind_enum" NOT NULL DEFAULT 'system',
        "title" character varying(200) NOT NULL,
        "body" text NOT NULL DEFAULT '',
        "data" jsonb,
        "read_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notifications" PRIMARY KEY ("id"),
        CONSTRAINT "FK_notifications_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_notifications_user_id" ON "notifications" ("user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_notifications_created_at"
        ON "notifications" ("created_at")
    `);

    await queryRunner.query(`
      CREATE TYPE "friend_requests_status_enum" AS ENUM (
        'Pending', 'Accepted', 'Rejected'
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "friend_requests" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "from_user_id" uuid NOT NULL,
        "to_user_id" uuid NOT NULL,
        "status" "friend_requests_status_enum" NOT NULL DEFAULT 'Pending',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_friend_requests" PRIMARY KEY ("id"),
        CONSTRAINT "FK_fr_from"
          FOREIGN KEY ("from_user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_fr_to"
          FOREIGN KEY ("to_user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_fr_to_user_id" ON "friend_requests" ("to_user_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_fr_from_user_id" ON "friend_requests" ("from_user_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "friendships" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_low_id" uuid NOT NULL,
        "user_high_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_friendships" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_friendships_pair"
          UNIQUE ("user_low_id", "user_high_id"),
        CONSTRAINT "FK_friendships_low"
          FOREIGN KEY ("user_low_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_friendships_high"
          FOREIGN KEY ("user_high_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_friendships_low" ON "friendships" ("user_low_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_friendships_high" ON "friendships" ("user_high_id")
    `);

    // Oversight audit stub — SuperAdmin transcript reads land here.
    await queryRunner.query(`
      CREATE TABLE "audit_logs" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "actor_id" uuid,
        "action" character varying(120) NOT NULL,
        "resource_type" character varying(80) NOT NULL,
        "resource_id" character varying(80),
        "meta" jsonb,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_audit_logs" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_audit_logs_created_at" ON "audit_logs" ("created_at")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "audit_logs"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "friendships"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "friend_requests"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "friend_requests_status_enum"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "notifications"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "notifications_kind_enum"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "moments"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "messages"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "messages_attachment_kind_enum"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "conversation_participants"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "conversations"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "conversations_kind_enum"`);
  }
}
