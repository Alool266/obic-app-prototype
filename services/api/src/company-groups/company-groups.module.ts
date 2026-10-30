// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import { User } from '../users/user.entity';
import { CompanyContactGroup, CompanyContactGroupMember } from './company-group.entities';
import {
  AdminCompanyGroupsController,
  CompanyGroupsController,
} from './company-groups.controller';
import { CompanyGroupsService } from './company-groups.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CompanyContactGroup,
      CompanyContactGroupMember,
      CompanyContact,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [CompanyGroupsController, AdminCompanyGroupsController],
  providers: [CompanyGroupsService],
})
export class CompanyGroupsModule {}
