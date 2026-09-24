// Made by Dr Ali

import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum FriendRequestStatus {
  Pending = 'Pending',
  Accepted = 'Accepted',
  Rejected = 'Rejected',
}

@Entity({ name: 'friend_requests' })
export class FriendRequest {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'from_user_id', type: 'uuid' })
  fromUserId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'from_user_id' })
  fromUser!: User;

  @Column({ name: 'to_user_id', type: 'uuid' })
  toUserId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'to_user_id' })
  toUser!: User;

  @Column({
    type: 'enum',
    enum: FriendRequestStatus,
    default: FriendRequestStatus.Pending,
  })
  status!: FriendRequestStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
