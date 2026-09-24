// Made by Dr Ali
// Staff-entered hotel / flight offers — media via /v1/uploads (same as Moments).

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
import { User } from '../users/user.entity';

/** Catalog slug: hotels | flights today; more types later. Same meaning as offer_type. */
export type OfferKind = string;

export type OfferMediaItem = {
  kind: 'image' | 'video' | 'file';
  url: string;
  name?: string;
  mime?: string;
  size?: number;
};

@Entity({ name: 'offers' })
export class Offer {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Catalog slug (offer type): hotels | flights | future types. */
  @Index()
  @Column({ type: 'varchar', length: 32 })
  kind!: OfferKind;

  @Column({ name: 'title_ar', type: 'varchar', length: 200 })
  titleAr!: string;

  @Column({ name: 'title_en', type: 'varchar', length: 200 })
  titleEn!: string;

  @Column({ name: 'body_ar', type: 'text', default: '' })
  bodyAr!: string;

  @Column({ name: 'body_en', type: 'text', default: '' })
  bodyEn!: string;

  /** Free-form price label shown to customers, e.g. "من 120$" / "From $120". */
  @Column({ name: 'price_label_ar', type: 'varchar', length: 120, nullable: true })
  priceLabelAr!: string | null;

  @Column({ name: 'price_label_en', type: 'varchar', length: 120, nullable: true })
  priceLabelEn!: string | null;

  /** Optional route/city line, e.g. "CAN → RUH" or "Guangzhou". */
  @Column({ name: 'location_label', type: 'varchar', length: 200, nullable: true })
  locationLabel!: string | null;

  /** Optional date range text entered by staff. */
  @Column({ name: 'dates_label', type: 'varchar', length: 200, nullable: true })
  datesLabel!: string | null;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  media!: OfferMediaItem[];

  /** Type-specific fields (room class, airline, seats, …) — no extra columns. */
  @Column({ type: 'jsonb', default: () => "'{}'" })
  attributes!: Record<string, unknown>;

  @Column({ name: 'is_published', type: 'boolean', default: false })
  isPublished!: boolean;

  /** Staff flag — customers cannot request or browse when true. */
  @Column({ name: 'is_sold_out', type: 'boolean', default: false })
  isSoldOut!: boolean;

  /** Optional hard end — after this instant the offer is hidden from customers. */
  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt!: Date | null;

  @Column({ name: 'created_by_id', type: 'uuid' })
  createdById!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'created_by_id' })
  createdBy!: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
