// Made by Dr Ali
// Channel video like — one row per user per video.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';
import { ChannelVideo } from './channel-video.entity';

@Entity({ name: 'channel_video_likes' })
@Unique(['videoId', 'userId'])
export class ChannelVideoLike {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'video_id', type: 'uuid' })
  videoId!: string;

  @ManyToOne(() => ChannelVideo, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'video_id' })
  video?: ChannelVideo;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
