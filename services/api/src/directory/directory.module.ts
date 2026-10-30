// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { Department } from './department.entity';
import {
  AdminDepartmentsController,
  DirectoryController,
} from './directory.controller';
import { DirectoryService } from './directory.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Department, User, AuditLog]),
    TotpModule,
  ],
  controllers: [DirectoryController, AdminDepartmentsController],
  providers: [DirectoryService],
  exports: [DirectoryService],
})
export class DirectoryModule {}
