// Made by Dr Ali
// User reports + auto flags from the send filter. SuperAdmin reviews.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export enum ReportTargetType {
  Message = 'message',
  Moment = 'moment',
  Comment = 'comment',
  Thread = 'thread',
}

export enum ReportSource {
  User = 'user',
  Auto = 'auto',
}

export enum ReportStatus {
  Open = 'open',
  Reviewed = 'reviewed',
  Dismissed = 'dismissed',
}

@Entity('content_reports')
export class ContentReport {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'reporter_id', type: 'uuid', nullable: true })
  reporterId!: string | null;

  @Column({
    name: 'target_type',
    type: 'enum',
    enum: ReportTargetType,
    enumName: 'content_reports_target_enum',
  })
  targetType!: ReportTargetType;

  @Column({ name: 'target_id', type: 'uuid' })
  targetId!: string;

  @Column({
    type: 'enum',
    enum: ReportSource,
    enumName: 'content_reports_source_enum',
    default: ReportSource.User,
  })
  source!: ReportSource;

  @Column({ type: 'varchar', length: 500, default: '' })
  reason!: string;

  @Column({ type: 'varchar', length: 160, default: '' })
  snippet!: string;

  @Index()
  @Column({
    type: 'enum',
    enum: ReportStatus,
    enumName: 'content_reports_status_enum',
    default: ReportStatus.Open,
  })
  status!: ReportStatus;

  @Column({ name: 'reviewed_by', type: 'uuid', nullable: true })
  reviewedBy!: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
