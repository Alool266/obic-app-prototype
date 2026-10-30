// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import { User } from '../users/user.entity';
import { CompanyContactTag, CompanyTag } from './company-tag.entities';
import {
  AdminCompanyTagsController,
  CompanyTagsController,
} from './company-tags.controller';
import { CompanyTagsService } from './company-tags.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyTag, CompanyContactTag, CompanyContact, User, AuditLog]),
    TotpModule,
  ],
  controllers: [CompanyTagsController, AdminCompanyTagsController],
  providers: [CompanyTagsService],
})
export class CompanyTagsModule {}
