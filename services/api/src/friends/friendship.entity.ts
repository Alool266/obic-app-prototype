// Made by Dr Ali
// Accepted friendship — store ordered pair (low, high) to keep uniqueness simple.

import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'friendships' })
@Unique(['userLowId', 'userHighId'])
export class Friendship {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_low_id', type: 'uuid' })
  userLowId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_low_id' })
  userLow!: User;

  @Column({ name: 'user_high_id', type: 'uuid' })
  userHighId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_high_id' })
  userHigh!: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
