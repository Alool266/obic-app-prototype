// Made by Dr Ali
// A company department. Visibility decides which staff can see its members.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { DirectoryVisibility } from './directory-visibility';

@Entity({ name: 'departments' })
export class Department {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'name_en', type: 'varchar', length: 120 })
  nameEn!: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 120 })
  nameAr!: string;

  @Column({ name: 'name_zh', type: 'varchar', length: 120 })
  nameZh!: string;

  /** Branch this department belongs to. Null means the whole company. */
  @Column({ name: 'branch_label', type: 'varchar', length: 120, nullable: true })
  branchLabel!: string | null;

  @Column({ type: 'varchar', length: 16, default: 'branch' })
  visibility!: DirectoryVisibility;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder!: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
