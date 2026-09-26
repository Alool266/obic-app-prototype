// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FriendsModule } from '../friends/friends.module';
import { ModerationModule } from '../moderation/moderation.module';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { User } from '../users/user.entity';
import { Channel } from './channel.entity';
import { ChannelFollow } from './channel-follow.entity';
import { ChannelVideo } from './channel-video.entity';
import { ChannelVideoComment } from './channel-video-comment.entity';
import { ChannelVideoLike } from './channel-video-like.entity';
import { ChannelsController } from './channels.controller';
import { ChannelsService } from './channels.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Channel,
      ChannelFollow,
      ChannelVideo,
      ChannelVideoLike,
      ChannelVideoComment,
      User,
    ]),
    ModerationModule,
    FriendsModule,
  ],
  controllers: [ChannelsController],
  providers: [ChannelsService, PhoneVerifiedGuard],
  exports: [ChannelsService],
})
export class ChannelsModule {}
