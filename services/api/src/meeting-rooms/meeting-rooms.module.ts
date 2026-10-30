// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { MeetingBooking, MeetingRoom } from './meeting-room.entities';
import {
  AdminMeetingRoomsController,
  MeetingRoomsController,
} from './meeting-rooms.controller';
import { MeetingRoomsService } from './meeting-rooms.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MeetingRoom, MeetingBooking, User, AuditLog]),
    TotpModule,
  ],
  controllers: [MeetingRoomsController, AdminMeetingRoomsController],
  providers: [MeetingRoomsService],
})
export class MeetingRoomsModule {}
