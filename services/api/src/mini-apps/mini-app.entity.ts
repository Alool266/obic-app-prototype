// Made by Dr Ali
// Partner mini-app submission. startUrl is the hosted package index, not a partner site.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { MiniAppStatus } from './mini-app-status';

@Entity({ name: 'mini_apps' })
export class MiniApp {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'owner_user_id', type: 'uuid' })
  ownerUserId!: string;

  @Column({ type: 'varchar', length: 80 })
  name!: string;

  @Column({ type: 'varchar', length: 400, default: '' })
  description!: string;

  @Column({ name: 'icon_url', type: 'varchar', length: 1024, nullable: true })
  iconUrl!: string | null;

  /** Hosted index path: /v1/mini-apps/:id/files/index.html. Never a partner URL. */
  @Column({ name: 'start_url', type: 'varchar', length: 2048 })
  startUrl!: string;

  /** Approved row this pending upload will replace once the boss approves it. */
  @Column({ name: 'supersedes_id', type: 'uuid', nullable: true })
  supersedesId!: string | null;

  /** Short-lived path secret so SuperAdmin can open a pending package. */
  @Column({ name: 'preview_ticket', type: 'varchar', length: 80, nullable: true })
  previewTicket!: string | null;

  @Index()
  @Column({ type: 'varchar', length: 16, default: MiniAppStatus.Pending })
  status!: MiniAppStatus;

  @Column({ name: 'review_note', type: 'varchar', length: 500, nullable: true })
  reviewNote!: string | null;

  @Column({ name: 'reviewer_user_id', type: 'uuid', nullable: true })
  reviewerUserId!: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
