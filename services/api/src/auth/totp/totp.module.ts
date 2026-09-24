// Made by Dr Ali

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TotpCryptoService } from './totp-crypto.service';
import { TotpService } from './totp.service';

@Module({
  imports: [ConfigModule],
  providers: [TotpCryptoService, TotpService],
  exports: [TotpCryptoService, TotpService],
})
export class TotpModule {}
