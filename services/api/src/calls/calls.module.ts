// Made by Dr Ali
// Phase 5 calls — Agora RTC token mint + ring (keys server-only).

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { RealtimeModule } from '../realtime/realtime.module';
import { User } from '../users/user.entity';
import { CallsConfig } from './calls.config';
import { CallsController } from './calls.controller';
import { CallsService } from './calls.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Conversation, ConversationParticipant, User]),
    RealtimeModule,
  ],
  controllers: [CallsController],
  providers: [CallsConfig, CallsService],
  exports: [CallsConfig, CallsService],
})
export class CallsModule {}
