// Made by Dr Ali
// One Non-VIP company-registration application (boss W1). Own state machine,
// frozen price snapshot, separate ContractID + TrackingID (Master Handoff §10).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type {
  AccountantTier,
  EligibilityOutcome,
  RegistrationStatus,
} from './registration';

@Entity('registration_applications')
export class RegistrationApplication {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Customer — always from JWT, never from the request body. */
  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  /** Public tracking reference shown to the customer, e.g. OBIC-REG-2026-483920. */
  @Index()
  @Column({ name: 'tracking_id', type: 'varchar', length: 32, unique: true })
  trackingId!: string;

  /** Set when the application is APPROVED; null before that. */
  @Column({ name: 'contract_id', type: 'varchar', length: 32, nullable: true })
  contractId!: string | null;

  @Column({ type: 'varchar', length: 60 })
  city!: string;

  @Column({ type: 'varchar', length: 80, nullable: true })
  area!: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  nationality!: string | null;

  /** Inside China now? Drives passport-authentication display + checklist. */
  @Column({ name: 'inside_china', type: 'boolean', default: false })
  insideChina!: boolean;

  @Column({ type: 'varchar', length: 120, nullable: true })
  qualification!: string | null;

  /** Business activity the customer wants to register. */
  @Column({ type: 'varchar', length: 120 })
  activity!: string;

  @Column({
    name: 'eligibility_outcome',
    type: 'varchar',
    length: 24,
    default: 'to_be_verified',
  })
  eligibilityOutcome!: EligibilityOutcome;

  @Column({
    name: 'eligibility_rule_version',
    type: 'varchar',
    length: 32,
    nullable: true,
  })
  eligibilityRuleVersion!: string | null;

  @Column({ name: 'eligibility_reason', type: 'text', nullable: true })
  eligibilityReason!: string | null;

  /** Customer-chosen accountant tier — never silently pre-selected (§7.4). */
  @Column({
    name: 'accountant_tier',
    type: 'varchar',
    length: 16,
    nullable: true,
  })
  accountantTier!: AccountantTier | null;

  @Column({ name: 'include_work_residence', type: 'boolean', default: false })
  includeWorkResidence!: boolean;

  @Column({ type: 'varchar', length: 24, default: 'DRAFT' })
  status!: RegistrationStatus;

  /** Frozen quote at submit: lines + totals + price versions. Never edited. */
  @Column({ name: 'price_snapshot', type: 'jsonb', nullable: true })
  priceSnapshot!: Record<string, unknown> | null;

  /** Customer form answers (contact, company wishes, prior China history…). */
  @Column({ name: 'form_data', type: 'jsonb', nullable: true })
  formData!: Record<string, unknown> | null;

  @Index()
  @Column({ name: 'assigned_employee_id', type: 'uuid', nullable: true })
  assignedEmployeeId!: string | null;

  @Column({ name: 'submitted_at', type: 'timestamptz', nullable: true })
  submittedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
