// Made by Dr Ali
// A reusable staff form, its fields, and one submission of answers.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { OfficeFieldType } from './office-form';

@Entity({ name: 'office_forms' })
export class OfficeForm {
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

@Entity({ name: 'office_form_fields' })
export class OfficeFormField {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'form_id', type: 'uuid' })
  formId!: string;

  @Column({ type: 'int' })
  position!: number;

  @Column({ name: 'field_key', type: 'varchar', length: 32 })
  fieldKey!: string;

  @Column({ name: 'label_en', type: 'varchar', length: 80 })
  labelEn!: string;

  @Column({ name: 'label_ar', type: 'varchar', length: 80 })
  labelAr!: string;

  @Column({ name: 'label_zh', type: 'varchar', length: 80 })
  labelZh!: string;

  @Column({ name: 'field_type', type: 'varchar', length: 16 })
  fieldType!: OfficeFieldType;

  @Column({ type: 'boolean', default: false })
  required!: boolean;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  options!: string[];
}

export type OfficeFieldSnapshot = {
  key: string;
  labelEn: string;
  labelAr: string;
  labelZh: string;
  type: OfficeFieldType;
  options: string[];
};

@Entity({ name: 'office_form_submissions' })
export class OfficeFormSubmission {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'form_id', type: 'uuid' })
  formId!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'jsonb' })
  answers!: Record<string, string>;

  /** Field labels at send time, so a later template edit does not rewrite this. */
  @Column({ name: 'fields_snapshot', type: 'jsonb' })
  fieldsSnapshot!: OfficeFieldSnapshot[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
