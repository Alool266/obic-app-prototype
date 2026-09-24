// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import { Offer } from './offer.entity';
import { AdminOffersController, OffersController } from './offers.controller';
import { OffersService } from './offers.service';

@Module({
  imports: [TypeOrmModule.forFeature([Offer, User])],
  controllers: [OffersController, AdminOffersController],
  providers: [OffersService],
  exports: [OffersService],
})
export class OffersModule {}
