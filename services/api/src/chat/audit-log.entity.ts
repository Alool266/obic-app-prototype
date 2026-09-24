// Made by Dr Ali
// Lightweight audit stub for SuperAdmin oversight (transcript reads, etc.).

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'audit_logs' })
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId!: string | null;

  @Column({ type: 'varchar', length: 120 })
  action!: string;

  @Column({ name: 'resource_type', type: 'varchar', length: 80 })
  resourceType!: string;

  @Column({ name: 'resource_id', type: 'varchar', length: 80, nullable: true })
  resourceId!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  meta!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
