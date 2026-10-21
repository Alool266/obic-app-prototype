// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiModule } from '../ai/ai.module';
import { AuditLog } from '../chat/audit-log.entity';
import { CompanyDocument } from '../company-documents/company-document.entity';
import { User } from '../users/user.entity';
import { CompanyFileAnswer } from './company-file-answer.entity';
import {
  AdminCompanyFileAnswersController,
  CompanyFileAnswersController,
} from './company-file-answers.controller';
import { CompanyFileAnswersService } from './company-file-answers.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CompanyFileAnswer, CompanyDocument, User, AuditLog]),
    AiModule,
  ],
  controllers: [CompanyFileAnswersController, AdminCompanyFileAnswersController],
  providers: [CompanyFileAnswersService],
})
export class CompanyFileAnswersModule {}
