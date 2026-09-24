// Made by Dr Ali
// Per-user inbox — always scoped by JWT userId.

import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum NotificationKind {
  Moment = 'moment',
  FriendRequest = 'friend_request',
  FriendAccepted = 'friend_accepted',
  Message = 'message',
  System = 'system',
  OrderCreated = 'order_created',
  OrderStatus = 'order_status',
}

@Entity({ name: 'notifications' })
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({
    type: 'enum',
    enum: NotificationKind,
    default: NotificationKind.System,
  })
  kind!: NotificationKind;

  @Column({ type: 'varchar', length: 200 })
  title!: string;

  @Column({ type: 'text', default: '' })
  body!: string;

  @Column({ type: 'jsonb', nullable: true })
  data!: Record<string, unknown> | null;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
