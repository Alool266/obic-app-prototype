// Made by Dr Ali
// Refresh sessions — store only a hash of the opaque refresh token.

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'refresh_sessions' })
export class RefreshSession {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  /** sha256 hex of the opaque refresh token presented to clients. */
  @Column({ name: 'token_hash', type: 'varchar', length: 64, unique: true })
  tokenHash!: string;

  /**
   * Rotation family — if a previously rotated token is reused,
   * revoke every session in the family (reuse detection).
   */
  @Index()
  @Column({ name: 'family_id', type: 'uuid' })
  familyId!: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt!: Date | null;

  /** Set when this token was rotated out in favor of a newer one. */
  @Column({ name: 'replaced_by_id', type: 'uuid', nullable: true })
  replacedById!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
