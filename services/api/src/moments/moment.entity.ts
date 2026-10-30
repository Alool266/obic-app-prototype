// Made by Dr Ali
// Social moment post — staff/admin posts may fan-out notifications.

import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'moments' })
export class Moment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'author_id', type: 'uuid' })
  authorId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author!: User;

  @Column({ type: 'text' })
  body!: string;

  /** Legacy single image — prefer `media`. Kept for older clients. */
  @Column({ name: 'image_url', type: 'varchar', length: 1024, nullable: true })
  imageUrl!: string | null;

  /**
   * WeChat-style attachments: up to 9 items.
   * { kind: 'image'|'video'|'file', url, name?, mime?, size? }
   */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  media!: Array<{
    kind: 'image' | 'video' | 'file';
    url: string;
    name?: string;
    mime?: string;
    size?: number;
  }>;

  /** True when poster was SuperAdmin/Employee — all users were notified. */
  @Column({ name: 'notify_all', type: 'boolean', default: false })
  notifyAll!: boolean;

  /**
   * WeChat 朋友圈 visibility:
   * - `public` — official/staff; everyone (incl. guests)
   * - `friends` — all mutual friends + author
   * - `private` — author only
   * - `partial` — author + `allowedUserIds`
   * - `exclude` — friends except `deniedUserIds`
   */
  @Column({ type: 'varchar', length: 16, default: 'friends' })
  visibility!:
    | 'public'
    | 'friends'
    | 'private'
    | 'partial'
    | 'exclude';

  /** Friend user ids who can see a `partial` Moment. */
  @Column({
    name: 'allowed_user_ids',
    type: 'jsonb',
    default: () => "'[]'",
  })
  allowedUserIds!: string[];

  /** Friend user ids excluded from an `exclude` Moment. */
  @Column({
    name: 'denied_user_ids',
    type: 'jsonb',
    default: () => "'[]'",
  })
  deniedUserIds!: string[];

  /** Soft-delete — hidden from feed; kept for moderation trail. */
  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
