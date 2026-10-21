// Made by Dr Ali
// One checklist document on a registration application, with full version
// history of uploads and staff decisions (boss NV-007…009).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { RegistrationApplication } from './registration-application.entity';
import type { RegistrationDocStatus, RegistrationDocType } from './registration';

export type RegistrationDocHistoryEntry = {
  version: number;
  action: string;
  actorId: string | null;
  fileUrl: string | null;
  note: string | null;
  at: string;
};

@Entity('registration_documents')
@Index(['applicationId', 'docType'], { unique: true })
export class RegistrationDocument {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'application_id', type: 'uuid' })
  applicationId!: string;

  @ManyToOne(() => RegistrationApplication, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'application_id' })
  application!: RegistrationApplication;

  @Column({ name: 'doc_type', type: 'varchar', length: 32 })
  docType!: RegistrationDocType;

  @Column({ type: 'varchar', length: 120 })
  label!: string;

  @Column({ type: 'boolean', default: true })
  required!: boolean;

  @Column({ type: 'varchar', length: 24, default: 'missing' })
  status!: RegistrationDocStatus;

  @Column({ name: 'file_url', type: 'varchar', length: 1024, nullable: true })
  fileUrl!: string | null;

  @Column({ name: 'file_name', type: 'varchar', length: 255, nullable: true })
  fileName!: string | null;

  /** Increments on every customer re-upload; history keeps all versions. */
  @Column({ type: 'int', default: 0 })
  version!: number;

  /** Staff correction/block reason shown to the customer (field + reason). */
  @Column({ name: 'review_note', type: 'text', nullable: true })
  reviewNote!: string | null;

  @Column({ name: 'reviewed_by', type: 'uuid', nullable: true })
  reviewedBy!: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt!: Date | null;

  @Column({ type: 'jsonb', nullable: true })
  history!: RegistrationDocHistoryEntry[] | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
