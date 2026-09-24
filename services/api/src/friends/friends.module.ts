// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsModule } from '../notifications/notifications.module';
import { User } from '../users/user.entity';
import { FriendRequest } from './friend-request.entity';
import { Friendship } from './friendship.entity';
import { FriendsController } from './friends.controller';
import { FriendsService } from './friends.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Friendship, FriendRequest, User]),
    NotificationsModule,
  ],
  controllers: [FriendsController],
  providers: [FriendsService],
  exports: [FriendsService],
})
export class FriendsModule {}
