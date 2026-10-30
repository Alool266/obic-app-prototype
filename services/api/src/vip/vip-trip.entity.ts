// Made by Dr Ali
// One VIP trip request with a frozen, versioned quotation (boss VIP Spec).
// The official group is created only after acceptance + recorded payment.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { TripPurpose, TripStatus } from './vip';

@Entity('vip_trips')
export class VipTrip {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Index()
  @Column({ name: 'tracking_id', type: 'varchar', length: 32, unique: true })
  trackingId!: string;

  /** BIZ | TOUR | MED | STU | INV | MIX */
  @Column({ type: 'varchar', length: 8 })
  purpose!: TripPurpose;

  @Column({ type: 'jsonb' })
  cities!: string[];

  @Column({ type: 'int' })
  days!: number;

  @Column({ type: 'int', default: 1 })
  people!: number;

  @Column({ name: 'budget_cents', type: 'int', nullable: true })
  budgetCents!: number | null;

  @Column({ type: 'varchar', length: 24, default: 'DRAFT' })
  status!: TripStatus;

  /** Frozen quotation: coordination line + add-on lines + totals + version. */
  @Column({ type: 'jsonb', nullable: true })
  quotation!: Record<string, unknown> | null;

  @Column({ name: 'quotation_version', type: 'int', default: 0 })
  quotationVersion!: number;

  @Column({ name: 'accepted_at', type: 'timestamptz', nullable: true })
  acceptedAt!: Date | null;

  /** External payment reference recorded by staff (no in-app payment yet). */
  @Column({ name: 'paid_reference', type: 'varchar', length: 120, nullable: true })
  paidReference!: string | null;

  @Column({ name: 'group_conversation_id', type: 'uuid', nullable: true })
  groupConversationId!: string | null;

  @Index()
  @Column({ name: 'assigned_employee_id', type: 'uuid', nullable: true })
  assignedEmployeeId!: string | null;

  @Column({ type: 'text', nullable: true })
  notes!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
