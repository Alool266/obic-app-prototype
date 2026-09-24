// Made by Dr Ali
// Shared guards — RolesGuard re-loads role from Postgres (JWT role is a hint only).

import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { User } from '../users/user.entity';
import { AdminTotpEnrollGuard } from './guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from './guards/admin-totp-stepup.guard';
import { RolesGuard } from './guards/roles.guard';
import { AdminIpAllowlistMiddleware } from './middleware/admin-ip-allowlist.middleware';

@Global()
@Module({
  imports: [ConfigModule, TypeOrmModule.forFeature([User]), TotpModule],
  providers: [
    RolesGuard,
    AdminTotpEnrollGuard,
    AdminTotpStepUpGuard,
    AdminIpAllowlistMiddleware,
  ],
  exports: [
    RolesGuard,
    AdminTotpEnrollGuard,
    AdminTotpStepUpGuard,
    AdminIpAllowlistMiddleware,
    TypeOrmModule,
  ],
})
export class CommonModule {}
