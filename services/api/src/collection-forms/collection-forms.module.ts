// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  CollectionForm,
  CollectionFormField,
  CollectionFormMember,
  CollectionFormResponse,
} from './collection-form.entities';
import {
  AdminCollectionFormsController,
  CollectionFormsController,
} from './collection-forms.controller';
import { CollectionFormsService } from './collection-forms.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CollectionForm,
      CollectionFormField,
      CollectionFormMember,
      CollectionFormResponse,
      User,
      AuditLog,
    ]),
    TotpModule,
  ],
  controllers: [CollectionFormsController, AdminCollectionFormsController],
  providers: [CollectionFormsService],
})
export class CollectionFormsModule {}
