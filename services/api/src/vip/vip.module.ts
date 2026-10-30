// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { Conversation } from '../chat/conversation.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { User } from '../users/user.entity';
import { PricesModule } from '../prices/prices.module';
import { VipConsultation } from './vip-consultation.entity';
import { VipTrip } from './vip-trip.entity';
import { AdminVipController, VipController } from './vip.controller';
import { VipService } from './vip.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      VipTrip,
      VipConsultation,
      Conversation,
      ConversationParticipant,
      User,
      AuditLog,
    ]),
    PricesModule,
  ],
  controllers: [VipController, AdminVipController],
  providers: [VipService],
  exports: [VipService],
})
export class VipModule {}
