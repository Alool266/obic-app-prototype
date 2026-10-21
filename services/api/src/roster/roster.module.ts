// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  AdminRosterController,
  RosterController,
} from './roster.controller';
import { StaffEmployment } from './roster.entity';
import { RosterService } from './roster.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([StaffEmployment, User, AuditLog]),
    TotpModule,
  ],
  controllers: [RosterController, AdminRosterController],
  providers: [RosterService],
})
export class RosterModule {}
