// Made by Dr Ali
// Short video clip on a Channel feed.

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
import { Channel } from './channel.entity';

@Entity({ name: 'channel_videos' })
export class ChannelVideo {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'channel_id', type: 'uuid' })
  channelId!: string;

  @ManyToOne(() => Channel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'channel_id' })
  channel?: Channel;

  @Column({ name: 'author_id', type: 'uuid' })
  authorId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author?: User;

  @Column({ name: 'video_url', type: 'varchar', length: 1024 })
  videoUrl!: string;

  @Column({ name: 'thumb_url', type: 'varchar', length: 1024, nullable: true })
  thumbUrl!: string | null;

  @Column({ type: 'varchar', length: 500, default: '' })
  caption!: string;

  @Column({ name: 'duration_sec', type: 'integer', nullable: true })
  durationSec!: number | null;

  @Column({ name: 'byte_size', type: 'integer', nullable: true })
  byteSize!: number | null;

  @Column({ name: 'like_count', type: 'integer', default: 0 })
  likeCount!: number;

  @Column({ name: 'comment_count', type: 'integer', default: 0 })
  commentCount!: number;

  @Column({ name: 'share_count', type: 'integer', default: 0 })
  shareCount!: number;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
