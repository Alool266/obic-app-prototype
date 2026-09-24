// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FriendsModule } from '../friends/friends.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ModerationModule } from '../moderation/moderation.module';
import { User } from '../users/user.entity';
import { MomentComment } from './moment-comment.entity';
import { MomentLike } from './moment-like.entity';
import { Moment } from './moment.entity';
import { MomentsController } from './moments.controller';
import { MomentsService } from './moments.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Moment, MomentLike, MomentComment, User]),
    NotificationsModule,
    ModerationModule,
    FriendsModule,
  ],
  controllers: [MomentsController],
  providers: [MomentsService],
})
export class MomentsModule {}
