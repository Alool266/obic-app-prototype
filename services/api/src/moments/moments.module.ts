// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FriendsModule } from '../friends/friends.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ModerationModule } from '../moderation/moderation.module';
import { User } from '../users/user.entity';
import { MomentComment } from './moment-comment.entity';
import { MomentFriendMute } from './moment-friend-mute.entity';
import { MomentLike } from './moment-like.entity';
import { MomentNotifyPrefs } from './moment-notify-prefs.entity';
import { MomentNotifyPrefsService } from './moment-notify-prefs.service';
import { Moment } from './moment.entity';
import { MomentsController } from './moments.controller';
import { MomentsService } from './moments.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Moment,
      MomentLike,
      MomentComment,
      MomentNotifyPrefs,
      MomentFriendMute,
      User,
    ]),
    NotificationsModule,
    ModerationModule,
    FriendsModule,
  ],
  controllers: [MomentsController],
  providers: [MomentsService, MomentNotifyPrefsService],
  exports: [MomentNotifyPrefsService],
})
export class MomentsModule {}
