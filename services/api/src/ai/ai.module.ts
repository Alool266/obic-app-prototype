// Made by Dr Ali
// Phase 5 AI module — assistant + history + grounding + chat auto-reply.

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Conversation } from '../chat/conversation.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Message } from '../chat/message.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RealtimeModule } from '../realtime/realtime.module';
import { User } from '../users/user.entity';
import { AiAssistantMessage } from './assistant-message.entity';
import { AiAssistantThread } from './assistant-thread.entity';
import { AppSetting } from './app-setting.entity';
import { AiAutoReplyService } from './ai-auto-reply.service';
import { AiConfig } from './ai.config';
import { AiController } from './ai.controller';
import { AiGroundingService } from './ai-grounding.service';
import { AiHistoryService } from './ai-history.service';
import { AiService } from './ai.service';
import { AiSettingsService } from './ai-settings.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Conversation,
      ConversationParticipant,
      Message,
      User,
      Order,
      AiAssistantThread,
      AiAssistantMessage,
      AppSetting,
    ]),
    NotificationsModule,
    RealtimeModule,
  ],
  controllers: [AiController],
  providers: [
    AiConfig,
    AiGroundingService,
    AiSettingsService,
    AiHistoryService,
    AiService,
    AiAutoReplyService,
  ],
  exports: [
    AiConfig,
    AiService,
    AiAutoReplyService,
    AiSettingsService,
    AiHistoryService,
    AiGroundingService,
  ],
})
export class AiModule {}
