// Made by Dr Ali
// Company work reports: who receives them, and one note per person per period.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { ReportKind } from './report-period';

export const DEFAULT_REPORT_SETTING_ID =
  '6f0e2a10-0003-4000-8000-000000000001';

@Entity({ name: 'work_report_settings' })
export class WorkReportSetting {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 64 })
  timezone!: string;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'work_report_reviewers' })
export class WorkReportReviewer {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'setting_id', type: 'uuid' })
  settingId!: string;

  @Column({ type: 'int' })
  position!: number;
}

@Entity({ name: 'work_reports' })
export class WorkReport {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 16 })
  kind!: ReportKind;

  @Column({ name: 'period_key', type: 'varchar', length: 16 })
  periodKey!: string;

  @Column({ type: 'varchar', length: 2000 })
  done!: string;

  @Column({ type: 'varchar', length: 2000 })
  plan!: string;

  @Column({ type: 'varchar', length: 1000, default: '' })
  blockers!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
