// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AiModule } from '../ai/ai.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { PricesModule } from '../prices/prices.module';
import { DocumentExtraction } from './document-extraction.entity';
import { EligibilityRule } from './eligibility-rule.entity';
import { RegistrationApplication } from './registration-application.entity';
import { RegistrationDocument } from './registration-document.entity';
import { RegistrationEvent } from './registration-event.entity';
import {
  AdminEligibilityRulesController,
  AdminRegistrationController,
  RegistrationController,
} from './registration.controller';
import { RegistrationService } from './registration.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      RegistrationApplication,
      RegistrationDocument,
      RegistrationEvent,
      EligibilityRule,
      DocumentExtraction,
      AuditLog,
      User,
    ]),
    TotpModule,
    PricesModule,
    AiModule,
  ],
  controllers: [
    RegistrationController,
    AdminRegistrationController,
    AdminEligibilityRulesController,
  ],
  providers: [RegistrationService],
  exports: [RegistrationService],
})
export class RegistrationModule {}
