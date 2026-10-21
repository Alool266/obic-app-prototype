// Made by Dr Ali
// Approval templates and the requests opened from them.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type {
  ApprovalRequestStatus,
  ApprovalStepStatus,
} from './approval-flow';

@Entity({ name: 'approval_templates' })
export class ApprovalTemplate {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'name_en', type: 'varchar', length: 120 })
  nameEn!: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 120 })
  nameAr!: string;

  @Column({ name: 'name_zh', type: 'varchar', length: 120 })
  nameZh!: string;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'approval_template_steps' })
export class ApprovalTemplateStep {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'template_id', type: 'uuid' })
  templateId!: string;

  @Column({ type: 'int' })
  position!: number;

  @Column({ name: 'approver_user_id', type: 'uuid' })
  approverUserId!: string;
}

@Entity({ name: 'approval_requests' })
export class ApprovalRequest {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'template_id', type: 'uuid' })
  templateId!: string;

  @Column({ name: 'requester_id', type: 'uuid' })
  requesterId!: string;

  @Column({ type: 'varchar', length: 160 })
  title!: string;

  @Column({ type: 'varchar', length: 2000, default: '' })
  body!: string;

  @Column({ type: 'varchar', length: 16, default: 'pending' })
  status!: ApprovalRequestStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'approval_request_steps' })
export class ApprovalRequestStep {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'request_id', type: 'uuid' })
  requestId!: string;

  @Column({ type: 'int' })
  position!: number;

  @Column({ name: 'approver_user_id', type: 'uuid' })
  approverUserId!: string;

  @Column({ type: 'varchar', length: 16 })
  status!: ApprovalStepStatus;

  @Column({ type: 'varchar', length: 500, nullable: true })
  comment!: string | null;

  @Column({ name: 'decided_at', type: 'timestamptz', nullable: true })
  decidedAt!: Date | null;

  @Column({ name: 'decided_by_user_id', type: 'uuid', nullable: true })
  decidedByUserId!: string | null;
}
