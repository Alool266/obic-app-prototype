// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TotpModule } from '../auth/totp/totp.module';
import { AuditLog } from '../chat/audit-log.entity';
import { User } from '../users/user.entity';
import { QuickReply } from './quick-reply.entity';
import {
  AdminQuickRepliesController,
  QuickRepliesController,
} from './quick-replies.controller';
import { QuickRepliesService } from './quick-replies.service';

@Module({
  imports: [TypeOrmModule.forFeature([QuickReply, User, AuditLog]), TotpModule],
  controllers: [QuickRepliesController, AdminQuickRepliesController],
  providers: [QuickRepliesService],
})
export class QuickRepliesModule {}
