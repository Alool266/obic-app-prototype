// Made by Dr Ali
// Chat thread — participants own access; SuperAdmin may oversee via audit path.

import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ConversationParticipant } from './conversation-participant.entity';
import { Message } from './message.entity';

export enum ConversationKind {
  Direct = 'direct',
  Support = 'support',
  Group = 'group',
  Order = 'order',
}

@Entity({ name: 'conversations' })
export class Conversation {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'enum', enum: ConversationKind, default: ConversationKind.Direct })
  kind!: ConversationKind;

  /** Linked service request — one thread per order. */
  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId!: string | null;

  /** Display title for group / named threads (optional). */
  @Column({ type: 'varchar', length: 120, nullable: true })
  title!: string | null;

  /**
   * Phase 5 — when true and AI env is on, customer messages on support/order
   * threads may get an OBIC AI auto-reply. Staff message pauses this (override).
   */
  @Column({ name: 'ai_auto_reply_enabled', type: 'boolean', default: true })
  aiAutoReplyEnabled!: boolean;

  @OneToMany(() => ConversationParticipant, (p) => p.conversation)
  participants!: ConversationParticipant[];

  @OneToMany(() => Message, (m) => m.conversation)
  messages!: Message[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
