// Made by Dr Ali
// OTP challenges for email/phone verification (register + channel changes).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export type VerificationChannel = 'email' | 'phone';
export type VerificationPurpose =
  | 'register'
  | 'login'
  | 'change_email'
  | 'change_phone';

@Entity({ name: 'verification_challenges' })
export class VerificationChallenge {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 16 })
  channel!: VerificationChannel;

  @Column({ type: 'varchar', length: 24 })
  purpose!: VerificationPurpose;

  /** Normalized email or phone the code was sent to. */
  @Column({ type: 'varchar', length: 320 })
  destination!: string;

  @Column({ name: 'code_hash', type: 'varchar', length: 128 })
  codeHash!: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @Column({ name: 'last_sent_at', type: 'timestamptz' })
  lastSentAt!: Date;

  @Column({ type: 'int', default: 0 })
  attempts!: number;

  /** Pending new email/phone for change_* purposes (JSON-safe string). */
  @Column({ name: 'pending_value', type: 'varchar', length: 320, nullable: true })
  pendingValue!: string | null;

  /**
   * Trial/debug only — plaintext OTP when delivery is log fallback.
   * Never returned to customers; SuperAdmin peek only when enabled.
   */
  @Column({ name: 'debug_code', type: 'varchar', length: 12, nullable: true })
  debugCode!: string | null;

  @Column({ name: 'delivery', type: 'varchar', length: 32, default: 'unknown' })
  delivery!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
