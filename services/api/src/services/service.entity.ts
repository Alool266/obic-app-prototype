// Made by Dr Ali
// Public service catalog row — browsable without auth.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('services')
export class Service {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 64 })
  slug!: string;

  @Column({ name: 'icon', type: 'varchar', length: 32 })
  icon!: string;

  /** Color theme key for primary tiles (hotels/flights/visa/bank/vip) or null. */
  @Column({ name: 'color_key', type: 'varchar', length: 32, nullable: true })
  colorKey!: string | null;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder!: number;

  @Column({ name: 'name_ar', type: 'varchar', length: 120 })
  nameAr!: string;

  @Column({ name: 'name_en', type: 'varchar', length: 120 })
  nameEn!: string;

  @Column({ name: 'name_zh', type: 'varchar', length: 120, default: '' })
  nameZh!: string;

  @Column({ name: 'desc_ar', type: 'text' })
  descAr!: string;

  @Column({ name: 'desc_en', type: 'text' })
  descEn!: string;

  @Column({ name: 'desc_zh', type: 'text', default: '' })
  descZh!: string;

  @Column({ name: 'price_ar', type: 'varchar', length: 80 })
  priceAr!: string;

  @Column({ name: 'price_en', type: 'varchar', length: 80 })
  priceEn!: string;

  @Column({ name: 'price_zh', type: 'varchar', length: 80, default: '' })
  priceZh!: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;

  /** ISO 3166-1 alpha-2 codes; empty = all countries. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  countries!: string[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
