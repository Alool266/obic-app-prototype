// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  AdminAttendanceController,
  AttendanceController,
} from './attendance.controller';
import { AttendancePunch, AttendanceRule } from './attendance.entities';
import { AttendanceService } from './attendance.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([AttendanceRule, AttendancePunch, User, AuditLog]),
    TotpModule,
  ],
  controllers: [AttendanceController, AdminAttendanceController],
  providers: [AttendanceService],
})
export class AttendanceModule {}
