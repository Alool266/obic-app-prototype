// Made by Dr Ali

import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Conversation } from './conversation.entity';

@Entity({ name: 'conversation_participants' })
@Unique(['conversationId', 'userId'])
export class ConversationParticipant {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'conversation_id', type: 'uuid' })
  conversationId!: string;

  @ManyToOne(() => Conversation, (c) => c.participants, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'conversation_id' })
  conversation!: Conversation;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'last_read_at', type: 'timestamptz', nullable: true })
  lastReadAt!: Date | null;

  /** WeChat mute — no notifs/badges for this thread for this user. */
  @Column({ type: 'boolean', default: false })
  muted!: boolean;

  /** WeChat hide — omit from thread list until new activity (or unhide). */
  @Column({ type: 'boolean', default: false })
  hidden!: boolean;

  /** Clear chat history for me — hide messages at/before this timestamp. */
  @Column({ name: 'cleared_before', type: 'timestamptz', nullable: true })
  clearedBefore!: Date | null;

  @CreateDateColumn({ name: 'joined_at', type: 'timestamptz' })
  joinedAt!: Date;
}
