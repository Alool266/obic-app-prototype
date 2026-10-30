// Made by Dr Ali
// A company quick reply, or one that belongs to a single staff member.

import { Column, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'company_quick_replies' })
export class QuickReply {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 24 })
  title!: string;

  @Column({ name: 'title_key', type: 'varchar', length: 24 })
  titleKey!: string;

  @Column({ type: 'varchar', length: 300 })
  body!: string;

  @Column({ name: 'owner_user_id', type: 'uuid', nullable: true })
  ownerUserId!: string | null;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
