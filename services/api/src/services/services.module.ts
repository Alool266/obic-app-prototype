// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminServicesController } from './admin-services.controller';
import { AdminSubServicesController } from './admin-sub-services.controller';
import { Service } from './service.entity';
import { ServiceSub } from './service-sub.entity';
import { ServicesController } from './services.controller';
import { ServicesService } from './services.service';

@Module({
  imports: [TypeOrmModule.forFeature([Service, ServiceSub])],
  controllers: [
    ServicesController,
    AdminServicesController,
    AdminSubServicesController,
  ],
  providers: [ServicesService],
  exports: [ServicesService],
})
export class ServicesModule {}
