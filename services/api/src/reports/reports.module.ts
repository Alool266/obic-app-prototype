// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  AdminReportsController,
  ReportsController,
} from './reports.controller';
import {
  WorkReport,
  WorkReportReviewer,
  WorkReportSetting,
} from './report.entities';
import { ReportsService } from './reports.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      WorkReportSetting,
      WorkReportReviewer,
      WorkReport,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [ReportsController, AdminReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}
