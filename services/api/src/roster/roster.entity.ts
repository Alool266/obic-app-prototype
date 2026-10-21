// Made by Dr Ali
// One employment row per staff member: join date, then an optional leave.

import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';
import type { EmploymentStatus } from './roster-status';

@Entity({ name: 'staff_employments' })
export class StaffEmployment {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'joined_on', type: 'varchar', length: 10 })
  joinedOn!: string;

  @Column({ type: 'varchar', length: 16 })
  status!: EmploymentStatus;

  @Column({ name: 'last_day', type: 'varchar', length: 10, nullable: true })
  lastDay!: string | null;

  @Column({ name: 'leave_note', type: 'varchar', length: 500, nullable: true })
  leaveNote!: string | null;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
