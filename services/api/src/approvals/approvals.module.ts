// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  ApprovalRequest,
  ApprovalRequestStep,
  ApprovalTemplate,
  ApprovalTemplateStep,
} from './approval.entities';
import {
  AdminApprovalTemplatesController,
  ApprovalsController,
} from './approvals.controller';
import { ApprovalsService } from './approvals.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ApprovalTemplate,
      ApprovalTemplateStep,
      ApprovalRequest,
      ApprovalRequestStep,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [ApprovalsController, AdminApprovalTemplatesController],
  providers: [ApprovalsService],
})
export class ApprovalsModule {}
