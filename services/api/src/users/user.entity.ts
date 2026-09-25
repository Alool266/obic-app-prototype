// Made by Dr Ali
// User entity — credentials stay hashed; never serialize passwordHash to clients.

import { Exclude } from 'class-transformer';
import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { UserAddress } from './user-address.interface';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 320, unique: true, nullable: true })
  email!: string | null;

  @Column({ type: 'varchar', length: 32, unique: true, nullable: true })
  phone!: string | null;

  /** bcrypt hash — excluded from every HTTP response via ClassSerializer. */
  @Exclude()
  @Column({ name: 'password_hash', type: 'varchar', length: 255 })
  passwordHash!: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.Customer })
  role!: UserRole;

  @Column({ type: 'varchar', length: 120 })
  name!: string;

  /**
   * Desk / job label for staff (e.g. Marketing Manager, Branch Manager).
   * Display + Form2 reassignment ACL (sales-rep / branch-manager patterns).
   * Privilege gates (promote, oversight, create staff) still use `role`.
   */
  @Column({ name: 'staff_title', type: 'varchar', length: 120, nullable: true })
  staffTitle!: string | null;

  /** Branch label for staff (e.g. Yiwu). Display only — not AuthZ. */
  @Column({ name: 'branch_label', type: 'varchar', length: 120, nullable: true })
  branchLabel!: string | null;

  /** Public avatar URL (uploaded or absolute). */
  @Column({ name: 'avatar_url', type: 'varchar', length: 1024, nullable: true })
  avatarUrl!: string | null;

  /** Profile city (self-service). */
  @Column({ type: 'varchar', length: 120, nullable: true })
  city!: string | null;

  /** Profile country (self-service). */
  @Column({ type: 'varchar', length: 120, nullable: true })
  country!: string | null;

  /**
   * OBIC ID — WeChat-style vanity handle friends use to find/add you.
   * Stored lowercase; unique when set. First set free; then once per 365 days.
   */
  @Column({ name: 'obic_id', type: 'varchar', length: 20, unique: true, nullable: true })
  obicId!: string | null;

  /** When OBIC ID was last set/changed (server-enforced cooldown). */
  @Column({ name: 'obic_id_changed_at', type: 'timestamptz', nullable: true })
  obicIdChangedAt!: Date | null;

  /**
   * Internal Ops desk access for Employees (SuperAdmin always allowed in API/UI).
   * Default false — SuperAdmin must grant per employee from Staff desk.
   */
  @Column({ name: 'ops_access', type: 'boolean', default: false })
  opsAccess!: boolean;

  /**
   * Hotel & flight offers desk access for Employees (SuperAdmin always allowed).
   * Default false — SuperAdmin must grant per employee from Staff desk.
   */
  @Column({ name: 'offers_access', type: 'boolean', default: false })
  offersAccess!: boolean;

  /** Encrypted TOTP secret (SuperAdmin 2FA). Never expose to clients. */
  @Exclude()
  @Column({ name: 'totp_secret_enc', type: 'text', nullable: true })
  totpSecretEnc!: string | null;

  /** Pending enroll secret until first code confirms. */
  @Exclude()
  @Column({ name: 'totp_pending_secret_enc', type: 'text', nullable: true })
  totpPendingSecretEnc!: string | null;

  @Column({ name: 'totp_enabled', type: 'boolean', default: false })
  totpEnabled!: boolean;

  /** Saved delivery / contact addresses (customer profile). */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  addresses!: UserAddress[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
