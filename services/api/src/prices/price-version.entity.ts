// Made by Dr Ali
// One versioned price row. Unique (price_id, version). Only Active rows quote.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { PriceStatus, PricingBasis } from './price';

@Entity('price_versions')
@Index(['priceId', 'version'], { unique: true })
@Index(['serviceKey', 'city', 'status'])
export class PriceVersion {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Stable business key, e.g. PRICE-YIW-REG. Never reused. */
  @Column({ name: 'price_id', type: 'varchar', length: 64 })
  priceId!: string;

  @Column({ type: 'varchar', length: 32 })
  version!: string;

  /** Catalog key, e.g. company-registration. */
  @Column({ name: 'service_key', type: 'varchar', length: 80 })
  serviceKey!: string;

  @Column({ name: 'item_name', type: 'varchar', length: 160 })
  itemName!: string;

  @Column({ type: 'varchar', length: 60, nullable: true })
  city!: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  nationality!: string | null;

  /** OBIC service fee, in minor units (cents). Never a government fee. */
  @Column({ name: 'obic_fee_cents', type: 'int', default: 0 })
  obicFeeCents!: number;

  /** Government / third-party fee, kept separate from the OBIC fee. */
  @Column({ name: 'external_fee_cents', type: 'int', default: 0 })
  externalFeeCents!: number;

  @Column({ type: 'varchar', length: 8, default: 'CNY' })
  currency!: string;

  @Column({ name: 'pricing_basis', type: 'varchar', length: 40, default: 'per_order' })
  pricingBasis!: PricingBasis;

  @Column({ type: 'varchar', length: 16, default: 'Draft' })
  status!: PriceStatus;

  @Column({ name: 'effective_from', type: 'date', nullable: true })
  effectiveFrom!: string | null;

  @Column({ name: 'effective_to', type: 'date', nullable: true })
  effectiveTo!: string | null;

  @Column({ name: 'approved_by', type: 'uuid', nullable: true })
  approvedBy!: string | null;

  @Column({ name: 'source_ref', type: 'varchar', length: 200, nullable: true })
  sourceRef!: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  note!: string | null;

  @Column({ name: 'created_by', type: 'uuid' })
  createdBy!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
