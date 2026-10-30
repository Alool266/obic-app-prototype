// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import { AiModule } from '../ai/ai.module';
import { ModerationModule } from '../moderation/moderation.module';
import { OrdersModule } from '../orders/orders.module';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { AuditLog } from './audit-log.entity';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { LiveLocationService } from './live-location.service';
import { ConversationParticipant } from './conversation-participant.entity';
import { Conversation } from './conversation.entity';
import { Message } from './message.entity';
import { FriendsModule } from '../friends/friends.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Conversation,
      ConversationParticipant,
      Message,
      AuditLog,
      User,
      Order,
    ]),
    ModerationModule,
    NotificationsModule,
    AiModule,
    OrdersModule,
    RealtimeModule,
    FriendsModule,
  ],
  controllers: [ChatController],
  providers: [ChatService, LiveLocationService, PhoneVerifiedGuard],
  exports: [ChatService],
})
export class ChatModule {}
