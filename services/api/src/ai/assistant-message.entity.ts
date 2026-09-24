// Made by Dr Ali
// One turn in an OBIC AI assistant thread.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'ai_assistant_messages' })
export class AiAssistantMessage {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_ai_assistant_messages_thread_id')
  @Column({ name: 'thread_id', type: 'uuid' })
  threadId!: string;

  @Column({ type: 'varchar', length: 16 })
  role!: 'user' | 'assistant';

  @Column({ type: 'text' })
  content!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
