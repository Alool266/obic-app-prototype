// Made by Dr Ali
// Per-user Home mega-icon order, favorites, and hidden slugs.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'user_home_layouts' })
export class UserHomeLayout {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  /** Visible grid order (service slugs). Empty = catalog default. */
  @Column({ name: 'order_slugs', type: 'jsonb', default: () => "'[]'" })
  orderSlugs!: string[];

  /** Favorite / pinned slugs — shown in the مفضّل row first. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  favorites!: string[];

  /** Hidden from Home only — still in All services / hubs. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  hidden!: string[];

  /** Mini-app shelf order (app ids). Empty = catalog default. */
  @Column({ name: 'mini_order', type: 'jsonb', default: () => "'[]'" })
  miniOrder!: string[];

  /** Mini-app favorites / pins. */
  @Column({ name: 'mini_favorites', type: 'jsonb', default: () => "'[]'" })
  miniFavorites!: string[];

  /** Mini-apps hidden from the shelf (still in All catalog). */
  @Column({ name: 'mini_hidden', type: 'jsonb', default: () => "'[]'" })
  miniHidden!: string[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
