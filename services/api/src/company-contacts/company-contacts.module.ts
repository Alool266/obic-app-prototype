// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyContact } from './company-contact.entity';
import {
  AdminCompanyContactsController,
  CompanyContactsController,
} from './company-contacts.controller';
import { CompanyContactsService } from './company-contacts.service';

@Module({
  imports: [TypeOrmModule.forFeature([CompanyContact, User, AuditLog]), TotpModule],
  controllers: [CompanyContactsController, AdminCompanyContactsController],
  providers: [CompanyContactsService],
})
export class CompanyContactsModule {}
