// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Friendship } from '../friends/friendship.entity';
import { UserOfficeController } from './user-office.controller';
import { UserOfficeItem } from './user-office-item.entity';
import { UserOfficeService } from './user-office.service';

@Module({
  imports: [TypeOrmModule.forFeature([UserOfficeItem, Friendship])],
  controllers: [UserOfficeController],
  providers: [UserOfficeService],
  exports: [UserOfficeService],
})
export class UserOfficeModule {}
