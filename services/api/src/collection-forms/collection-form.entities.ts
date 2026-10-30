// Made by Dr Ali
// One collection sent to many staff. Each person has one row of answers.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { OfficeFieldSnapshot } from '../office-forms/office-form.entities';
import type { OfficeFieldType } from '../office-forms/office-form';

@Entity({ name: 'collection_forms' })
export class CollectionForm {
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

@Entity({ name: 'collection_form_fields' })
export class CollectionFormField {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'collection_id', type: 'uuid' })
  collectionId!: string;

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

@Entity({ name: 'collection_form_members' })
export class CollectionFormMember {
  @PrimaryColumn({ name: 'collection_id', type: 'uuid' })
  collectionId!: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;
}

@Entity({ name: 'collection_form_responses' })
export class CollectionFormResponse {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'collection_id', type: 'uuid' })
  collectionId!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'jsonb' })
  answers!: Record<string, string>;

  @Column({ name: 'fields_snapshot', type: 'jsonb' })
  fieldsSnapshot!: OfficeFieldSnapshot[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
