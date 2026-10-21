// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyMeeting, CompanyMeetingAttendee } from './company-meeting.entities';
import {
  AdminCompanyMeetingsController,
  CompanyMeetingsController,
} from './company-meetings.controller';
import { CompanyMeetingsService } from './company-meetings.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyMeeting, CompanyMeetingAttendee, User, AuditLog]),
    TotpModule,
  ],
  controllers: [CompanyMeetingsController, AdminCompanyMeetingsController],
  providers: [CompanyMeetingsService],
})
export class CompanyMeetingsModule {}
