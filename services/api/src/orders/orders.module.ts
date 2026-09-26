// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { Message } from '../chat/message.entity';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { NotificationsModule } from '../notifications/notifications.module';
import { OffersModule } from '../offers/offers.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { ServicesModule } from '../services/services.module';
import { User } from '../users/user.entity';
import { OrderChatService } from './order-chat.service';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Order,
      User,
      Conversation,
      ConversationParticipant,
      Message,
      AuditLog,
    ]),
    ServicesModule,
    OffersModule,
    NotificationsModule,
    RealtimeModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrderChatService, PhoneVerifiedGuard],
  exports: [OrderChatService],
})
export class OrdersModule {}
