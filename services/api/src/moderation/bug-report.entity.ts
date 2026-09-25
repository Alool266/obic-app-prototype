// Made by Dr Ali
// In-app bug reports (description + photos) — staff review queue.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum BugReportStatus {
  Open = 'open',
  InProgress = 'in_progress',
  Resolved = 'resolved',
  Dismissed = 'dismissed',
}

@Entity({ name: 'bug_reports' })
export class BugReport {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ name: 'photo_urls', type: 'jsonb', default: () => "'[]'" })
  photoUrls!: string[];

  @Index()
  @Column({ type: 'varchar', length: 32, default: BugReportStatus.Open })
  status!: BugReportStatus;

  @Column({ name: 'reviewed_by', type: 'uuid', nullable: true })
  reviewedBy!: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
