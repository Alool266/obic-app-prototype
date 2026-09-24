// Made by Dr Ali
// SuperAdmin-editable phrase list. Matching is server-side only.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('banned_words')
export class BannedWord {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 120 })
  phrase!: string;

  @Column({ type: 'varchar', length: 40, default: 'general' })
  category!: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
