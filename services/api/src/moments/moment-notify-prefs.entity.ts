// Made by Dr Ali
// Per-user Moments notification prefs (server-backed, sync across devices).

import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'moment_notify_prefs' })
export class MomentNotifyPrefs {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** When false, Moments tab never badges and fan-out skips this user. */
  @Column({ name: 'notify_enabled', type: 'boolean', default: true })
  notifyEnabled!: boolean;

  /** WeChat-style mute Moments updates — same effect as notify off for badge. */
  @Column({ name: 'mute_updates', type: 'boolean', default: false })
  muteUpdates!: boolean;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
