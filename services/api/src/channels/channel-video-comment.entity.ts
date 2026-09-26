// Made by Dr Ali
// Comment on a Channel short video.

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
import { ChannelVideo } from './channel-video.entity';

@Entity({ name: 'channel_video_comments' })
export class ChannelVideoComment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'video_id', type: 'uuid' })
  videoId!: string;

  @ManyToOne(() => ChannelVideo, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'video_id' })
  video?: ChannelVideo;

  @Column({ name: 'author_id', type: 'uuid' })
  authorId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author?: User;

  @Column({ type: 'varchar', length: 500, default: '' })
  body!: string;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
