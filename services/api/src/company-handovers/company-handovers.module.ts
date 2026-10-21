// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import {
  CompanyContactGroup,
  CompanyContactGroupMember,
} from '../company-groups/company-group.entities';
import { User } from '../users/user.entity';
import { CompanyContactHandover } from './company-handover.entity';
import {
  AdminCompanyHandoversController,
  CompanyHandoversController,
} from './company-handovers.controller';
import { CompanyHandoversService } from './company-handovers.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CompanyContactHandover,
      CompanyContact,
      CompanyContactGroup,
      CompanyContactGroupMember,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [CompanyHandoversController, AdminCompanyHandoversController],
  providers: [CompanyHandoversService],
})
export class CompanyHandoversModule {}
