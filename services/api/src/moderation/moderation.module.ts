// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Message } from '../chat/message.entity';
import { MomentComment } from '../moments/moment-comment.entity';
import { Moment } from '../moments/moment.entity';
import { AdminModerationController } from './admin-moderation.controller';
import { BannedWord } from './banned-word.entity';
import { BugReport } from './bug-report.entity';
import { BugReportsController } from './bug-reports.controller';
import { BugReportsService } from './bug-reports.service';
import { ContentReport } from './content-report.entity';
import { ModerationController } from './moderation.controller';
import { ModerationService } from './moderation.service';
import { User } from '../users/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      BannedWord,
      ContentReport,
      BugReport,
      Message,
      ConversationParticipant,
      Moment,
      MomentComment,
      User,
    ]),
  ],
  controllers: [
    ModerationController,
    AdminModerationController,
    BugReportsController,
  ],
  providers: [ModerationService, BugReportsService],
  exports: [ModerationService, BugReportsService],
})
export class ModerationModule {}
