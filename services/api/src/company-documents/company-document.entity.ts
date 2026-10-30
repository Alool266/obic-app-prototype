// Made by Dr Ali
// One shared company document. The text is not a drive file.

import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'company_documents' })
export class CompanyDocument {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 80 })
  title!: string;

  @Column({ name: 'title_key', type: 'varchar', length: 80 })
  titleKey!: string;

  @Column({ type: 'varchar', length: 8000 })
  body!: string;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @Column({ name: 'updated_by', type: 'uuid' })
  updatedBy!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
