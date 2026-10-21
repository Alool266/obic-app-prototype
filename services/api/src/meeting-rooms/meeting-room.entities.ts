// Made by Dr Ali
// A company meeting room and one booking for a stretch of time.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export const MEETING_BOOKING_STATUSES = ['booked', 'cancelled'] as const;
export type MeetingBookingStatus = (typeof MEETING_BOOKING_STATUSES)[number];

@Entity({ name: 'meeting_rooms' })
export class MeetingRoom {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'name_en', type: 'varchar', length: 120 })
  nameEn!: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 120 })
  nameAr!: string;

  @Column({ name: 'name_zh', type: 'varchar', length: 120 })
  nameZh!: string;

  @Column({ name: 'branch_label', type: 'varchar', length: 120, nullable: true })
  branchLabel!: string | null;

  @Column({ type: 'int' })
  capacity!: number;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'meeting_bookings' })
export class MeetingBooking {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'room_id', type: 'uuid' })
  roomId!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 120 })
  title!: string;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt!: Date;

  @Column({ name: 'ends_at', type: 'timestamptz' })
  endsAt!: Date;

  @Column({ type: 'varchar', length: 16, default: 'booked' })
  status!: MeetingBookingStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
