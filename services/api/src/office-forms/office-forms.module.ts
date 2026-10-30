// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  OfficeForm,
  OfficeFormField,
  OfficeFormSubmission,
} from './office-form.entities';
import {
  AdminOfficeFormsController,
  OfficeFormsController,
} from './office-forms.controller';
import { OfficeFormsService } from './office-forms.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      OfficeForm,
      OfficeFormField,
      OfficeFormSubmission,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [OfficeFormsController, AdminOfficeFormsController],
  providers: [OfficeFormsService],
})
export class OfficeFormsModule {}
