// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyWelcome, CompanyWelcomeAssignment } from './company-welcome.entities';
import {
  AdminCompanyWelcomesController,
  CompanyWelcomesController,
} from './company-welcomes.controller';
import { CompanyWelcomesService } from './company-welcomes.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyWelcome, CompanyWelcomeAssignment, User, AuditLog]),
    TotpModule,
  ],
  controllers: [CompanyWelcomesController, AdminCompanyWelcomesController],
  providers: [CompanyWelcomesService],
})
export class CompanyWelcomesModule {}
