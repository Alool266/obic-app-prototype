// Made by Dr Ali
// One OCR extraction run against one document version, with the three-way
// comparison and the human reviewer's decision (boss M04). Nothing here
// ever overwrites customer data — decisions are recorded, fields are not.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { FieldComparison, PassportConfidences, PassportFields } from './ocr';

@Entity('document_extractions')
export class DocumentExtraction {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'application_id', type: 'uuid' })
  applicationId!: string;

  @Index()
  @Column({ name: 'document_id', type: 'uuid' })
  documentId!: string;

  @Column({ name: 'doc_type', type: 'varchar', length: 32 })
  docType!: string;

  /** Document version that was read (re-uploads increment it). */
  @Column({ name: 'doc_version', type: 'int' })
  docVersion!: number;

  @Column({ type: 'varchar', length: 40 })
  provider!: string;

  @Column({ name: 'model_version', type: 'varchar', length: 120 })
  modelVersion!: string;

  @Column({ name: 'extracted_fields', type: 'jsonb' })
  extractedFields!: PassportFields;

  @Column({ type: 'jsonb', nullable: true })
  confidence!: PassportConfidences | null;

  @Column({ type: 'jsonb' })
  comparisons!: FieldComparison[];

  /** True when any field mismatches typed/saved values → human queue. */
  @Column({ name: 'has_mismatch', type: 'boolean', default: false })
  hasMismatch!: boolean;

  /** pending_review | confirmed | rejected | superseded */
  @Column({ type: 'varchar', length: 24, default: 'pending_review' })
  status!: string;

  @Column({ name: 'reviewed_by', type: 'uuid', nullable: true })
  reviewedBy!: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt!: Date | null;

  @Column({ name: 'review_note', type: 'text', nullable: true })
  reviewNote!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
