// Made by Dr Ali
// One staff question answered from shared documents.

import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'company_file_answers' })
export class CompanyFileAnswer {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 300 })
  question!: string;

  @Column({ type: 'varchar', length: 2000 })
  answer!: string;

  @Column({ type: 'jsonb' })
  sources!: string[];

  @Column({ name: 'answered_by', type: 'varchar', length: 12 })
  answeredBy!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
