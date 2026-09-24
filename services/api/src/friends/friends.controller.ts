// Made by Dr Ali
// /v1/friends — JWT; Employees cannot add Customers (enforced in service).

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { SendFriendRequestDto } from './dto/friends.dto';
import { FriendsService } from './friends.service';

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friends: FriendsService) {}

  @Get()
  list(@CurrentUser() actor: AuthUser) {
    return this.friends.listFriends(actor);
  }

  @Get('search')
  search(@CurrentUser() actor: AuthUser, @Query('q') q = '') {
    return this.friends.search(actor, q);
  }

  @Get('requests')
  listRequests(@CurrentUser() actor: AuthUser) {
    return this.friends.listRequests(actor);
  }

  @Post('requests')
  send(@CurrentUser() actor: AuthUser, @Body() dto: SendFriendRequestDto) {
    return this.friends.sendRequest(actor, dto);
  }

  @Post('requests/:id/accept')
  accept(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.friends.accept(actor, id);
  }

  @Post('requests/:id/reject')
  reject(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.friends.reject(actor, id);
  }
}
