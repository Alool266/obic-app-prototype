// Made by Dr Ali
// Channels HTTP — official + per-user + feed tabs + engagement.

import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../common/guards/optional-jwt-auth.guard';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { isChannelFeedTab } from './channel-visibility';
import { ChannelsService } from './channels.service';
import { CreateChannelCommentDto } from './dto/create-channel-comment.dto';
import { CreateChannelVideoDto } from './dto/create-channel-video.dto';

@Controller('channels')
export class ChannelsController {
  constructor(private readonly channels: ChannelsService) {}

  // ── Meta / discover / feed (static paths before :idOrSlug) ───────────

  @Get('obic/limits')
  limits() {
    return this.channels.limits();
  }

  @Get('limits')
  limitsAlias() {
    return this.channels.limits();
  }

  @Get('discover')
  @UseGuards(OptionalJwtAuthGuard)
  discover(@Req() req: Request & { user?: AuthUser }) {
    return this.channels.discoverPreview(req.user?.userId ?? null);
  }

  @Get('feed')
  @UseGuards(OptionalJwtAuthGuard)
  feed(
    @Req() req: Request & { user?: AuthUser },
    @Query('tab') tabRaw?: string,
    @Query('limit') limit?: string,
  ) {
    const tab = (tabRaw ?? 'hot').toLowerCase();
    if (!isChannelFeedTab(tab)) {
      throw new BadRequestException(
        'tab must be follow|nearby|friends|hot',
      );
    }
    const n = limit ? Number.parseInt(limit, 10) : 40;
    return this.channels.feed(
      tab,
      Number.isFinite(n) ? n : 40,
      req.user?.userId ?? null,
    );
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() actor: AuthUser) {
    return this.channels.getMine(actor);
  }

  @Get('user/:userId')
  @UseGuards(OptionalJwtAuthGuard)
  byUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Req() req: Request & { user?: AuthUser },
  ) {
    return this.channels.getByUserId(userId, req.user?.userId ?? null);
  }

  // ── Official OBIC (back-compat) ──────────────────────────────────────

  @Get('obic')
  @UseGuards(OptionalJwtAuthGuard)
  getObic(@Req() req: Request & { user?: AuthUser }) {
    return this.channels.getObic(req.user?.userId ?? null);
  }

  @Post('obic/follow')
  @UseGuards(JwtAuthGuard)
  followObic(@CurrentUser() actor: AuthUser) {
    return this.channels.followObic(actor);
  }

  @Delete('obic/follow')
  @UseGuards(JwtAuthGuard)
  unfollowObic(@CurrentUser() actor: AuthUser) {
    return this.channels.unfollowObic(actor);
  }

  @Get('obic/videos')
  @UseGuards(OptionalJwtAuthGuard)
  listObicVideos(
    @Req() req: Request & { user?: AuthUser },
    @Query('limit') limit?: string,
  ) {
    const n = limit ? Number.parseInt(limit, 10) : 40;
    return this.channels.listObicVideos(
      Number.isFinite(n) ? n : 40,
      req.user?.userId ?? null,
    );
  }

  @Post('obic/videos')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  createObicVideo(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateChannelVideoDto,
  ) {
    return this.channels.createObicVideo(actor, dto);
  }

  @Delete('obic/videos/:id')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  removeObicVideo(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.channels.softDeleteVideo(actor, id);
  }

  // ── Video engagement (before :idOrSlug) ──────────────────────────────

  @Post('videos/:videoId/like')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  like(
    @CurrentUser() actor: AuthUser,
    @Param('videoId', ParseUUIDPipe) videoId: string,
  ) {
    return this.channels.toggleLike(actor, videoId);
  }

  @Get('videos/:videoId/comments')
  @UseGuards(OptionalJwtAuthGuard)
  listComments(
    @Param('videoId', ParseUUIDPipe) videoId: string,
    @Req() req: Request & { user?: AuthUser },
    @Query('limit') limit?: string,
  ) {
    const n = limit ? Number.parseInt(limit, 10) : 40;
    return this.channels.listComments(
      videoId,
      req.user?.userId ?? null,
      Number.isFinite(n) ? n : 40,
    );
  }

  @Post('videos/:videoId/comments')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  addComment(
    @CurrentUser() actor: AuthUser,
    @Param('videoId', ParseUUIDPipe) videoId: string,
    @Body() dto: CreateChannelCommentDto,
  ) {
    return this.channels.addComment(actor, videoId, dto);
  }

  @Post('videos/:videoId/share')
  @UseGuards(JwtAuthGuard)
  share(
    @CurrentUser() actor: AuthUser,
    @Param('videoId', ParseUUIDPipe) videoId: string,
  ) {
    return this.channels.share(actor, videoId);
  }

  @Delete('videos/:videoId')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  removeVideo(
    @CurrentUser() actor: AuthUser,
    @Param('videoId', ParseUUIDPipe) videoId: string,
  ) {
    return this.channels.softDeleteVideo(actor, videoId);
  }

  // ── Generic channel by id or slug ────────────────────────────────────

  @Get(':idOrSlug')
  @UseGuards(OptionalJwtAuthGuard)
  getOne(
    @Param('idOrSlug') idOrSlug: string,
    @Req() req: Request & { user?: AuthUser },
  ) {
    return this.channels.getByIdOrSlug(idOrSlug, req.user?.userId ?? null);
  }

  @Post(':idOrSlug/follow')
  @UseGuards(JwtAuthGuard)
  follow(
    @CurrentUser() actor: AuthUser,
    @Param('idOrSlug') idOrSlug: string,
  ) {
    return this.channels.followByIdOrSlug(actor, idOrSlug);
  }

  @Delete(':idOrSlug/follow')
  @UseGuards(JwtAuthGuard)
  unfollow(
    @CurrentUser() actor: AuthUser,
    @Param('idOrSlug') idOrSlug: string,
  ) {
    return this.channels.unfollowByIdOrSlug(actor, idOrSlug);
  }

  @Get(':idOrSlug/videos')
  @UseGuards(OptionalJwtAuthGuard)
  listVideos(
    @Param('idOrSlug') idOrSlug: string,
    @Req() req: Request & { user?: AuthUser },
    @Query('limit') limit?: string,
  ) {
    const n = limit ? Number.parseInt(limit, 10) : 40;
    return this.channels.listVideosByIdOrSlug(
      idOrSlug,
      Number.isFinite(n) ? n : 40,
      req.user?.userId ?? null,
    );
  }

  @Post(':idOrSlug/videos')
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
  createVideo(
    @CurrentUser() actor: AuthUser,
    @Param('idOrSlug') idOrSlug: string,
    @Body() dto: CreateChannelVideoDto,
  ) {
    return this.channels.createVideoByIdOrSlug(actor, idOrSlug, dto);
  }
}
