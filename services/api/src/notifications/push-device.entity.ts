// Made by Dr Ali
// One row per phone that should receive Apple or Google push.

import { Column, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'push_devices' })
@Index('UQ_push_devices_token', ['token'], { unique: true })
export class PushDevice {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 16 })
  platform!: string;

  @Column({ type: 'varchar', length: 512 })
  token!: string;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
