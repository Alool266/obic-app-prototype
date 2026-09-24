// Made by Dr Ali
// Server-persisted OBIC AI assistant chat thread (per user).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'ai_assistant_threads' })
export class AiAssistantThread {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_ai_assistant_threads_user_id')
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 120 })
  title!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
