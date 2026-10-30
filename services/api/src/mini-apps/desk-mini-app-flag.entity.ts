// Made by Dr Ali
// Desk enable/disable for first-party mini-apps (single-tenant company).

import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'desk_mini_app_flags' })
export class DeskMiniAppFlag {
  @PrimaryColumn({ name: 'app_id', type: 'varchar', length: 64 })
  appId!: string;

  @Column({ type: 'boolean', default: true })
  enabled!: boolean;

  @Column({ name: 'updated_by', type: 'uuid', nullable: true })
  updatedBy!: string | null;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
