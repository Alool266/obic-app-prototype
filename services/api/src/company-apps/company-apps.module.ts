// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyApp } from './company-app.entity';
import { AdminCompanyAppsController, CompanyAppsController } from './company-apps.controller';
import { CompanyAppsService } from './company-apps.service';

@Module({
  imports: [TypeOrmModule.forFeature([CompanyApp, User, AuditLog]), TotpModule],
  controllers: [CompanyAppsController, AdminCompanyAppsController],
  providers: [CompanyAppsService],
})
export class CompanyAppsModule {}
