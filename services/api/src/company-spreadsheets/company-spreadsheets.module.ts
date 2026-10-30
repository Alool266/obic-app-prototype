// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanySpreadsheet } from './company-spreadsheet.entity';
import {
  AdminCompanySpreadsheetsController,
  CompanySpreadsheetsController,
} from './company-spreadsheets.controller';
import { CompanySpreadsheetsService } from './company-spreadsheets.service';

@Module({
  imports: [TypeOrmModule.forFeature([CompanySpreadsheet, User, AuditLog]), TotpModule],
  controllers: [CompanySpreadsheetsController, AdminCompanySpreadsheetsController],
  providers: [CompanySpreadsheetsService],
})
export class CompanySpreadsheetsModule {}
