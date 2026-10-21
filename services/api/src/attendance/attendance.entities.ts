// Made by Dr Ali
// One company clock rule, and one in/out punch per person per company day.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { PunchKind, PunchMark } from './attendance-clock';

export const DEFAULT_ATTENDANCE_RULE_ID =
  '6f0e2a10-0002-4000-8000-000000000001';

@Entity({ name: 'attendance_rules' })
export class AttendanceRule {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 64 })
  timezone!: string;

  @Column({ name: 'start_minute', type: 'int' })
  startMinute!: number;

  @Column({ name: 'end_minute', type: 'int' })
  endMinute!: number;

  @Column({ name: 'grace_minutes', type: 'int', default: 0 })
  graceMinutes!: number;

  /** ISO weekdays, Monday = 1, stored as "1,2,3,4,5". */
  @Column({ type: 'varchar', length: 16 })
  weekdays!: string;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'attendance_punches' })
export class AttendancePunch {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'work_date', type: 'date' })
  workDate!: string;

  @Column({ type: 'varchar', length: 8 })
  kind!: PunchKind;

  @Column({ name: 'punched_at', type: 'timestamptz' })
  punchedAt!: Date;

  @Column({ type: 'varchar', length: 200, nullable: true })
  note!: string | null;

  @Column({ type: 'varchar', length: 16 })
  mark!: PunchMark;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
