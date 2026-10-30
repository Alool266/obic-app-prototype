// Made by Dr Ali
// Timeline / audit trail for a registration application (boss §5: actor,
// timestamp, old/new value, reason). Customer-caused delay is marked with
// delayParty so it is never counted as company processing time (NV-010).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('registration_events')
export class RegistrationEvent {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'application_id', type: 'uuid' })
  applicationId!: string;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId!: string | null;

  /** customer | staff | system */
  @Column({ name: 'actor_type', type: 'varchar', length: 16 })
  actorType!: string;

  @Column({ type: 'varchar', length: 60 })
  action!: string;

  @Column({ name: 'from_status', type: 'varchar', length: 24, nullable: true })
  fromStatus!: string | null;

  @Column({ name: 'to_status', type: 'varchar', length: 24, nullable: true })
  toStatus!: string | null;

  /** Document/field the event is about, when applicable. */
  @Column({ type: 'varchar', length: 60, nullable: true })
  field!: string | null;

  @Column({ type: 'text', nullable: true })
  note!: string | null;

  /** customer | company | null — whose clock a waiting period belongs to. */
  @Column({ name: 'delay_party', type: 'varchar', length: 16, nullable: true })
  delayParty!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  meta!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
