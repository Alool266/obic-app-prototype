// Made by Dr Ali
// Customer service request / order — ownership is user_id from JWT only.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Offer } from '../offers/offer.entity';
import { Service } from '../services/service.entity';
import { User } from '../users/user.entity';

export enum OrderStatus {
  Submitted = 'Submitted',
  Assigned = 'Assigned',
  InProgress = 'InProgress',
  WaitingCustomer = 'WaitingCustomer',
  Completed = 'Completed',
  Cancelled = 'Cancelled',
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Owner — always set from JWT subject; never from client body. */
  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'service_id', type: 'uuid' })
  serviceId!: string;

  @ManyToOne(() => Service, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'service_id' })
  service!: Service;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    enumName: 'orders_status_enum',
    default: OrderStatus.Submitted,
  })
  status!: OrderStatus;

  @Column({ name: 'preferred_branch', type: 'varchar', length: 80, nullable: true })
  preferredBranch!: string | null;

  /** Inner service selected inside a home service box. */
  @Column({ name: 'sub_service_id', type: 'varchar', length: 80, nullable: true })
  subServiceId!: string | null;

  @Column({ name: 'sub_service_name_en', type: 'varchar', length: 160, nullable: true })
  subServiceNameEn!: string | null;

  @Column({ name: 'sub_service_name_ar', type: 'varchar', length: 160, nullable: true })
  subServiceNameAr!: string | null;

  /** Structured customer form answers (JSON). */
  @Column({ name: 'form_data', type: 'jsonb', nullable: true })
  formData!: Record<string, unknown> | null;

  @Column({ type: 'text', nullable: true })
  notes!: string | null;

  /** Optional link when the customer requested a hotel/flight offer. */
  @Index()
  @Column({ name: 'offer_id', type: 'uuid', nullable: true })
  offerId!: string | null;

  @ManyToOne(() => Offer, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'offer_id' })
  offer!: Offer | null;

  /**
   * Employee assignment — null = unassigned pool (SuperAdmin sees all;
   * Employee only sees rows where this equals their userId).
   */
  @Index()
  @Column({ name: 'assigned_employee_id', type: 'uuid', nullable: true })
  assignedEmployeeId!: string | null;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_employee_id' })
  assignedEmployee!: User | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
