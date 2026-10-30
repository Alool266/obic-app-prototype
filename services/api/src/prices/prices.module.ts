// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { PriceVersion } from './price-version.entity';
import { AdminPricesController, PricesController } from './prices.controller';
import { PricesService } from './prices.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([PriceVersion, AuditLog, User]),
    TotpModule,
  ],
  controllers: [PricesController, AdminPricesController],
  providers: [PricesService],
  exports: [PricesService],
})
export class PricesModule {}
