// Made by Dr Ali
// Per-friend "don't let them see my Moments" (WeChat 不让他看).

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

@Entity({ name: 'moment_friend_hides' })
@Unique(['userId', 'hiddenFromFriendId'])
export class MomentFriendHide {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Author who hides their Moments from the friend. */
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** Friend who must not see this author's Moments. */
  @Column({ name: 'hidden_from_friend_id', type: 'uuid' })
  hiddenFromFriendId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hidden_from_friend_id' })
  hiddenFromFriend!: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
