// Made by Dr Ali
// One versioned eligibility rule (boss M03/M15). Rules follow the same
// Draft → Review → Approved → Active → Retired workflow as prices; only
// Active, human-approved rows may produce an eligibility outcome.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { PriceStatus } from '../prices/price';

@Entity('eligibility_rules')
@Index(['city', 'activity', 'version'], { unique: true })
export class EligibilityRule {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 32 })
  version!: string;

  @Column({ type: 'varchar', length: 60 })
  city!: string;

  @Column({ type: 'varchar', length: 120 })
  activity!: string;

  /** Null = any nationality. */
  @Column({ type: 'varchar', length: 80, nullable: true })
  nationality!: string | null;

  /** Null = applies whether the customer is inside or outside China. */
  @Column({ name: 'inside_china', type: 'boolean', nullable: true })
  insideChina!: boolean | null;

  @Column({ type: 'varchar', length: 16 })
  outcome!: 'eligible' | 'ineligible';

  @Column({ type: 'text', nullable: true })
  reason!: string | null;

  /** Cities offered when ineligible (boss SH-004). */
  @Column({ name: 'alternative_cities', type: 'jsonb', nullable: true })
  alternativeCities!: string[] | null;

  @Column({ type: 'varchar', length: 16, default: 'Draft' })
  status!: PriceStatus;

  @Column({ name: 'effective_from', type: 'date', nullable: true })
  effectiveFrom!: string | null;

  @Column({ name: 'effective_to', type: 'date', nullable: true })
  effectiveTo!: string | null;

  @Column({ name: 'approved_by', type: 'uuid', nullable: true })
  approvedBy!: string | null;

  /** Official source the rule was verified against (lawyer/accountant). */
  @Column({ name: 'source_ref', type: 'varchar', length: 200, nullable: true })
  sourceRef!: string | null;

  @Column({ name: 'created_by', type: 'uuid' })
  createdBy!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
