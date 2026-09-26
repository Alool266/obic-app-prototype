// Made by Dr Ali
// WeChat 视频号–style Channel — official OBIC or per-user personal.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'channels' })
export class Channel {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 64, unique: true })
  slug!: string;

  @Column({ type: 'varchar', length: 120 })
  name!: string;

  @Column({ type: 'varchar', length: 1024, nullable: true })
  description!: string | null;

  @Column({ name: 'avatar_url', type: 'varchar', length: 1024, nullable: true })
  avatarUrl!: string | null;

  @Column({ name: 'cover_url', type: 'varchar', length: 1024, nullable: true })
  coverUrl!: string | null;

  /** Official OBIC brand channel (role-gated posts). */
  @Index()
  @Column({ type: 'boolean', default: false })
  official!: boolean;

  /**
   * Personal channel owner. Null for official brand channels.
   * Unique when set — one channel per user.
   */
  @Index({ unique: true, where: '"owner_user_id" IS NOT NULL' })
  @Column({ name: 'owner_user_id', type: 'uuid', nullable: true })
  ownerUserId!: string | null;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'owner_user_id' })
  owner?: User | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
