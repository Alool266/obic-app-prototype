// Made by Dr Ali
// GET /v1/moments public browse; write actions require JWT.
// Notify-prefs routes registered before :id so they are not captured.

import {
  Body,
  Controller,
  Delete,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Get,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../common/guards/optional-jwt-auth.guard';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateMomentCommentDto } from './dto/create-moment-comment.dto';
import { CreateMomentDto } from './dto/create-moment.dto';
import { UpdateMomentNotifyPrefsDto } from './dto/moment-notify-prefs.dto';
import { MomentNotifyPrefsService } from './moment-notify-prefs.service';
import { MomentsService } from './moments.service';

@Controller('moments')
export class MomentsController {
  constructor(
    private readonly moments: MomentsService,
    private readonly notifyPrefs: MomentNotifyPrefsService,
  ) {}

  @Get('notify-prefs')
  @UseGuards(JwtAuthGuard)
  getNotifyPrefs(@CurrentUser() actor: AuthUser) {
    return this.notifyPrefs.getMine(actor);
  }

  @Patch('notify-prefs')
  @UseGuards(JwtAuthGuard)
  updateNotifyPrefs(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateMomentNotifyPrefsDto,
  ) {
    return this.notifyPrefs.updateMine(actor, dto);
  }

  @Post('notify-prefs/muted-friends/:friendId')
  @UseGuards(JwtAuthGuard)
  muteFriend(
    @CurrentUser() actor: AuthUser,
    @Param('friendId', ParseUUIDPipe) friendId: string,
  ) {
    return this.notifyPrefs.muteFriend(actor, friendId);
  }

  @Delete('notify-prefs/muted-friends/:friendId')
  @UseGuards(JwtAuthGuard)
  unmuteFriend(
    @CurrentUser() actor: AuthUser,
    @Param('friendId', ParseUUIDPipe) friendId: string,
  ) {
    return this.notifyPrefs.unmuteFriend(actor, friendId);
  }

  /** Don't let this friend see my Moments (WeChat 不让他看). */
  @Post('notify-prefs/hidden-from/:friendId')
  @UseGuards(JwtAuthGuard)
  hideFromFriend(
    @CurrentUser() actor: AuthUser,
    @Param('friendId', ParseUUIDPipe) friendId: string,
  ) {
    return this.notifyPrefs.hideFromFriend(actor, friendId);
  }

  @Delete('notify-prefs/hidden-from/:friendId')
  @UseGuards(JwtAuthGuard)
  unhideFromFriend(
    @CurrentUser() actor: AuthUser,
    @Param('friendId', ParseUUIDPipe) friendId: string,
  ) {
    return this.notifyPrefs.unhideFromFriend(actor, friendId);
  }

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  list(@Req() req: Request & { user?: AuthUser }) {
    return this.moments.listFeed(50, req.user?.userId ?? null);
  }

  /** One friend’s Moments album (ACL-filtered). Before :id routes. */
  @Get('user/:userId')
  @UseGuards(OptionalJwtAuthGuard)
  listForUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Req() req: Request & { user?: AuthUser },
  ) {
    return this.moments.listForUser(userId, 50, req.user?.userId ?? null);
  }

  @Post()
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateMomentDto) {
    return this.moments.create(actor, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  remove(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.moments.softDelete(actor, id);
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  like(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.moments.toggleLike(actor, id);
  }

  @Post(':id/comments')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  comment(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateMomentCommentDto,
  ) {
    return this.moments.addComment(actor, id, dto);
  }

  /** Comment author or moment author may soft-delete (WeChat-style). */
  @Delete(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  removeComment(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('commentId', ParseUUIDPipe) commentId: string,
  ) {
    return this.moments.softDeleteComment(actor, id, commentId);
  }
}
