// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyCalendarEvent } from './company-calendar.entity';
import {
  AdminCompanyCalendarController,
  CompanyCalendarController,
} from './company-calendar.controller';
import { CompanyCalendarService } from './company-calendar.service';

@Module({
  imports: [TypeOrmModule.forFeature([CompanyCalendarEvent, User, AuditLog]), TotpModule],
  controllers: [CompanyCalendarController, AdminCompanyCalendarController],
  providers: [CompanyCalendarService],
})
export class CompanyCalendarModule {}
