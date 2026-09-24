// Made by Dr Ali
// Inner service row — child of a catalog service (hub item).

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
import { Service } from './service.entity';

@Entity('service_subs')
export class ServiceSub {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'service_id', type: 'uuid' })
  serviceId!: string;

  @ManyToOne(() => Service, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'service_id' })
  service!: Service;

  /** Stable client id e.g. hotels-book — unique per parent service. */
  @Column({ name: 'external_id', type: 'varchar', length: 80 })
  externalId!: string;

  @Column({ type: 'varchar', length: 32 })
  icon!: string;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder!: number;

  @Column({ name: 'name_ar', type: 'varchar', length: 160 })
  nameAr!: string;

  @Column({ name: 'name_en', type: 'varchar', length: 160 })
  nameEn!: string;

  @Column({ name: 'name_zh', type: 'varchar', length: 160, default: '' })
  nameZh!: string;

  @Column({ name: 'desc_ar', type: 'text', default: '' })
  descAr!: string;

  @Column({ name: 'desc_en', type: 'text', default: '' })
  descEn!: string;

  @Column({ name: 'desc_zh', type: 'text', default: '' })
  descZh!: string;

  @Column({ name: 'price_ar', type: 'varchar', length: 80, default: '' })
  priceAr!: string;

  @Column({ name: 'price_en', type: 'varchar', length: 80, default: '' })
  priceEn!: string;

  @Column({ name: 'price_zh', type: 'varchar', length: 80, default: '' })
  priceZh!: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  countries!: string[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
