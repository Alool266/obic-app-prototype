// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import {
  AdminPayslipsController,
  PayslipsController,
} from './payslips.controller';
import { StaffPayslip } from './payslip.entity';
import { PayslipsService } from './payslips.service';

@Module({
  imports: [TypeOrmModule.forFeature([StaffPayslip, User, AuditLog]), TotpModule],
  controllers: [PayslipsController, AdminPayslipsController],
  providers: [PayslipsService],
})
export class PayslipsModule {}
