// Made by Dr Ali
// One recorded move of company contacts between two staff members.

import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';
import type { HandoverContactSnap } from './company-handover';

@Entity({ name: 'company_contact_handovers' })
export class CompanyContactHandover {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'from_user_id', type: 'uuid' })
  fromUserId!: string;

  @Column({ name: 'to_user_id', type: 'uuid' })
  toUserId!: string;

  @Column({ name: 'actor_user_id', type: 'uuid' })
  actorUserId!: string;

  @Column({ name: 'contact_count', type: 'int' })
  contactCount!: number;

  @Column({ type: 'jsonb' })
  contacts!: HandoverContactSnap[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
