// Made by Dr Ali
// Company directory: departments, who can see them, and a staff assignment.

import { MigrationInterface, QueryRunner } from 'typeorm';

export class DirectoryDepartments1765600000000 implements MigrationInterface {
  name = 'DirectoryDepartments1765600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "departments" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "name_en" varchar(120) NOT NULL,
        "name_ar" varchar(120) NOT NULL,
        "name_zh" varchar(120) NOT NULL,
        "branch_label" varchar(120),
        "visibility" varchar(16) NOT NULL DEFAULT 'branch',
        "sort_order" integer NOT NULL DEFAULT 0,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_departments" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_departments_visibility"
          CHECK ("visibility" IN ('company', 'branch', 'department'))
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN IF NOT EXISTS "department_id" uuid NULL
    `);
    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'FK_users_department'
        ) THEN
          ALTER TABLE "users"
            ADD CONSTRAINT "FK_users_department"
            FOREIGN KEY ("department_id") REFERENCES "departments"("id")
            ON DELETE SET NULL;
        END IF;
      END $$;
    `);
    await queryRunner.query(`
      INSERT INTO "departments"
        ("id", "name_en", "name_ar", "name_zh", "branch_label", "visibility", "sort_order")
      VALUES
        ('6f0e2a10-0001-4000-8000-000000000001', 'Leadership', 'الإدارة العليا', '管理层', 'Yiwu', 'company', 10),
        ('6f0e2a10-0001-4000-8000-000000000002', 'Marketing', 'التسويق', '市场部', 'Yiwu', 'branch', 20),
        ('6f0e2a10-0001-4000-8000-000000000003', 'Visas', 'الفيز', '签证部', 'Yiwu', 'branch', 30),
        ('6f0e2a10-0001-4000-8000-000000000004', 'Companies', 'الشركات', '公司注册', 'Yiwu', 'branch', 40),
        ('6f0e2a10-0001-4000-8000-000000000005', 'Purchasing', 'المشتريات', '采购部', 'Yiwu', 'branch', 50),
        ('6f0e2a10-0001-4000-8000-000000000006', 'Scholarships', 'المنح', '奖学金', 'Yiwu', 'branch', 60),
        ('6f0e2a10-0001-4000-8000-000000000007', 'Shipping', 'الشحن', '物流部', 'Yiwu', 'branch', 70),
        ('6f0e2a10-0001-4000-8000-000000000008', 'General', 'أخرى', '综合', 'Yiwu', 'branch', 80),
        ('6f0e2a10-0001-4000-8000-000000000009', 'Guangzhou office', 'مكتب قوانغتشو', '广州办事处', 'Guangzhou', 'branch', 90),
        ('6f0e2a10-0001-4000-8000-00000000000a', 'Foshan office', 'مكتب فوشان', '佛山办事处', 'Foshan', 'branch', 100),
        ('6f0e2a10-0001-4000-8000-00000000000b', 'Hangzhou office', 'مكتب هانغتشو', '杭州办事处', 'Hangzhou', 'branch', 110),
        ('6f0e2a10-0001-4000-8000-00000000000c', 'Hainan office', 'مكتب هاينان', '海南办事处', 'Hainan', 'branch', 120),
        ('6f0e2a10-0001-4000-8000-00000000000d', 'Yemen office', 'مكتب اليمن', '也门办事处', 'Yemen', 'branch', 130),
        ('6f0e2a10-0001-4000-8000-00000000000e', 'Shanghai office', 'مكتب شنغهاي', '上海办事处', 'Shanghai', 'branch', 140)
      ON CONFLICT ("id") DO NOTHING
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "FK_users_department"
    `);
    await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "department_id"
    `);
    await queryRunner.query(`DROP TABLE IF EXISTS "departments"`);
  }
}
