// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyDriveFile, CompanyDriveFolder } from './company-drive.entities';
import {
  AdminCompanyDriveController,
  CompanyDriveController,
} from './company-drive.controller';
import { CompanyDriveService } from './company-drive.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyDriveFolder, CompanyDriveFile, User, AuditLog]),
    TotpModule,
  ],
  controllers: [CompanyDriveController, AdminCompanyDriveController],
  providers: [CompanyDriveService],
})
export class CompanyDriveModule {}
