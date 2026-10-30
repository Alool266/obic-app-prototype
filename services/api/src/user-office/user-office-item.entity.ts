// Made by Dr Ali
// Personal Notes / Documents / Spreadsheets / PDF refs — user storage.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type UserOfficeKind = 'note' | 'document' | 'spreadsheet' | 'pdf';

@Entity({ name: 'user_office_items' })
export class UserOfficeItem {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 20 })
  kind!: UserOfficeKind;

  @Column({ type: 'varchar', length: 120, default: '' })
  title!: string;

  @Column({ type: 'text', default: '' })
  body!: string;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  grid!: string[][];

  @Column({ name: 'file_url', type: 'varchar', length: 500, nullable: true })
  fileUrl!: string | null;

  @Column({ name: 'share_user_ids', type: 'jsonb', default: () => "'[]'" })
  shareUserIds!: string[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
