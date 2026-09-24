// Made by Dr Ali
// Moment comment — WeChat-style text replies under a post.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Moment } from './moment.entity';

@Entity({ name: 'moment_comments' })
export class MomentComment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'moment_id', type: 'uuid' })
  momentId!: string;

  @ManyToOne(() => Moment, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'moment_id' })
  moment!: Moment;

  @Column({ name: 'author_id', type: 'uuid' })
  authorId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author!: User;

  @Column({ type: 'varchar', length: 500 })
  body!: string;

  /** WeChat-style: reply to another comment on the same moment (flat list). */
  @Index()
  @Column({ name: 'reply_to_comment_id', type: 'uuid', nullable: true })
  replyToCommentId!: string | null;

  @ManyToOne(() => MomentComment, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'reply_to_comment_id' })
  replyToComment!: MomentComment | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
