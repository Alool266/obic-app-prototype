// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { AdminMiniAppsController } from './admin-mini-apps.controller';
import { DeskMiniAppFlag } from './desk-mini-app-flag.entity';
import { MiniAppFile } from './mini-app-file.entity';
import { MiniApp } from './mini-app.entity';
import { MiniAppsController } from './mini-apps.controller';
import { MiniAppsService } from './mini-apps.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MiniApp, MiniAppFile, DeskMiniAppFlag, User]),
    NotificationsModule,
  ],
  controllers: [MiniAppsController, AdminMiniAppsController],
  providers: [MiniAppsService],
})
export class MiniAppsModule {}
