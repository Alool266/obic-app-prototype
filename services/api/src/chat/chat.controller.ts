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
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { SetAiAutoReplyDto } from '../ai/dto/ai.dto';
import { ChatService } from './chat.service';
import {
  CreateThreadDto,
  RequestStaffDto,
  SendMessageDto,
} from './dto/chat.dto';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  @Get('threads')
  listThreads(@CurrentUser() actor: AuthUser) {
    return this.chat.listThreads(actor);
  }

  @Post('threads')
  openThread(@CurrentUser() actor: AuthUser, @Body() dto: CreateThreadDto) {
    return this.chat.openOrCreateThread(actor, dto);
  }

  @Get('threads/:id/messages')
  listMessages(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.chat.listMessages(actor, id);
  }

  @Post('threads/:id/messages')
  sendMessage(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chat.sendMessage(actor, id, dto);
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
