// Made by Dr Ali
// /v1/chat — JWT for all private chat; SuperAdmin oversight under /admin.

import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { SetAiAutoReplyDto } from '../ai/dto/ai.dto';
import { ChatService } from './chat.service';
import {
  CreateThreadDto,
  RequestStaffDto,
  AddParticipantsDto,
  LiveLocationDto,
  SendMessageDto,
  StopLiveLocationDto,
  UpdateThreadPrefsDto,
} from './dto/chat.dto';
import { LiveLocationService } from './live-location.service';

@Controller('chat')
@UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly liveLocation: LiveLocationService,
  ) {}

  @Get('live-location')
  listLive(
    @CurrentUser() actor: AuthUser,
    @Query('conversationId') conversationId?: string,
  ) {
    if (!conversationId) return { shares: [] };
    return this.liveLocation.list(actor, conversationId);
  }

  @Post('live-location')
  shareLive(@CurrentUser() actor: AuthUser, @Body() dto: LiveLocationDto) {
    return this.liveLocation.upsert(actor, dto);
  }

  @Post('live-location/stop')
  stopLive(@CurrentUser() actor: AuthUser, @Body() dto: StopLiveLocationDto) {
    return this.liveLocation.stop(actor, dto.conversationId);
  }

  @Get('threads')
  listThreads(@CurrentUser() actor: AuthUser) {
    return this.chat.listThreads(actor);
  }

  /** Light unread feed for phones that cannot use Google push. */
  @Get('alert-feed')
  alertFeed(
    @CurrentUser() actor: AuthUser,
    @Query('after') after?: string,
  ) {
    return this.chat.alertFeed(actor, after);
  }

  @Post('threads')
  openThread(@CurrentUser() actor: AuthUser, @Body() dto: CreateThreadDto) {
    return this.chat.openOrCreateThread(actor, dto);
  }

  @Get('threads/:id/messages')
  listMessages(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query('since') since?: string,
  ) {
    return this.chat.listMessages(actor, id, since);
  }

  @Patch('threads/:id/prefs')
  updateThreadPrefs(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateThreadPrefsDto,
  ) {
    return this.chat.updateThreadPrefs(actor, id, dto);
  }

  @Post('threads/:id/messages')
  sendMessage(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chat.sendMessage(actor, id, dto);
  }

  /** WeChat recall — sender only, within 2 minutes. */
  @Post('threads/:id/messages/:messageId/recall')
  recallMessage(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('messageId', ParseUUIDPipe) messageId: string,
  ) {
    return this.chat.recallMessage(actor, id, messageId);
  }

  /** Staff override: pause or resume AI auto-reply on this thread. */
  @Patch('threads/:id/ai-auto-reply')
  @UseGuards(RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  setAiAutoReply(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SetAiAutoReplyDto,
  ) {
    return this.chat.setAiAutoReply(actor, id, dto.enabled);
  }

  /**
   * Customer “Talk to staff”: pause AI, route to desk queue / order assignee,
   * notify staff. Support + order threads only.
   */
  @Post('threads/:id/request-staff')
  @UseGuards(RolesGuard)
  @Roles(UserRole.Customer)
  requestStaff(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RequestStaffDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    const locale =
      dto?.locale ?? acceptLanguage?.split(',')[0] ?? undefined;
    return this.chat.requestStaff(actor, id, {
      locale,
      branch: dto?.branch,
      serviceKey: dto?.serviceKey ?? dto?.desk,
      orderRef: dto?.orderRef,
      note: dto?.note,
    });
  }

  /** Staff: list same-branch desk employees to invite into this support/order chat. */
  @Get('threads/:id/invite-candidates')
  @UseGuards(RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  listInviteCandidates(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.chat.listInviteCandidates(actor, id);
  }

  /** Any member can add accepted friends to a group chat. */
  @Post('threads/:id/members')
  addGroupMembers(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddParticipantsDto,
  ) {
    return this.chat.addGroupMembers(actor, id, dto.userIds ?? []);
  }

  /** Staff: add desk employees to an existing support/order thread. */
  @Post('threads/:id/participants')
  @UseGuards(RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  addParticipants(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddParticipantsDto,
  ) {
    return this.chat.addParticipants(actor, id, dto.userIds ?? []);
  }

  @Get('admin/employee-chats')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SuperAdmin)
  listEmployeeChats(@CurrentUser() actor: AuthUser) {
    return this.chat.listEmployeeChats(actor);
  }

  @Get('admin/threads/:id/messages')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SuperAdmin)
  adminTranscript(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.chat.adminReadTranscript(actor, id);
  }
}
