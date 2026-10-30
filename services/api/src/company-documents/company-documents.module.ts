// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyDocument } from './company-document.entity';
import {
  AdminCompanyDocumentsController,
  CompanyDocumentsController,
} from './company-documents.controller';
import { CompanyDocumentsService } from './company-documents.service';

@Module({
  imports: [TypeOrmModule.forFeature([CompanyDocument, User, AuditLog]), TotpModule],
  controllers: [CompanyDocumentsController, AdminCompanyDocumentsController],
  providers: [CompanyDocumentsService],
})
export class CompanyDocumentsModule {}
