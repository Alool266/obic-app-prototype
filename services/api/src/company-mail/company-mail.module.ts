// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { CompanyMailMessage, CompanyMailRecipient } from './company-mail.entities';
import { AdminCompanyMailController, CompanyMailController } from './company-mail.controller';
import { CompanyMailService } from './company-mail.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyMailMessage, CompanyMailRecipient, User, AuditLog]),
    TotpModule,
  ],
  controllers: [CompanyMailController, AdminCompanyMailController],
  providers: [CompanyMailService],
})
export class CompanyMailModule {}
