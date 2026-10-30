// Made by Dr Ali
// One timed VIP consultation (boss Master Handoff §9): 10/20/30/60 minutes,
// hard stop at endsAt, no auto-extension, no auto-charge. Buying more time
// means buying a NEW session.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { SessionStatus } from './vip';

@Entity('vip_consultations')
export class VipConsultation {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'int' })
  minutes!: number;

  @Column({ name: 'price_id', type: 'varchar', length: 64 })
  priceId!: string;

  /** Frozen price line at purchase time (PriceID + version + USD cents). */
  @Column({ name: 'price_snapshot', type: 'jsonb', nullable: true })
  priceSnapshot!: Record<string, unknown> | null;

  @Column({ type: 'varchar', length: 24, default: 'PENDING_PAYMENT' })
  status!: SessionStatus;

  @Column({ name: 'paid_reference', type: 'varchar', length: 120, nullable: true })
  paidReference!: string | null;

  @Column({ name: 'staff_user_id', type: 'uuid', nullable: true })
  staffUserId!: string | null;

  @Column({ name: 'started_at', type: 'timestamptz', nullable: true })
  startedAt!: Date | null;

  @Column({ name: 'ends_at', type: 'timestamptz', nullable: true })
  endsAt!: Date | null;

  @Column({ name: 'ended_at', type: 'timestamptz', nullable: true })
  endedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
