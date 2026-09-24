// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Message } from '../chat/message.entity';
import { MomentComment } from '../moments/moment-comment.entity';
import { Moment } from '../moments/moment.entity';
import { AdminModerationController } from './admin-moderation.controller';
import { BannedWord } from './banned-word.entity';
import { ContentReport } from './content-report.entity';
import { ModerationController } from './moderation.controller';
import { ModerationService } from './moderation.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      BannedWord,
      ContentReport,
      Message,
      ConversationParticipant,
      Moment,
      MomentComment,
    ]),
  ],
  controllers: [ModerationController, AdminModerationController],
  providers: [ModerationService],
  exports: [ModerationService],
})
export class ModerationModule {}
