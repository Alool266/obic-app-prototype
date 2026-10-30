// Made by Dr Ali
// GET/PATCH /v1/notifications — JWT + ownership (userId from token).

import {
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@CurrentUser() actor: AuthUser) {
    return this.notifications.listMine(actor);
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() actor: AuthUser) {
    return this.notifications.unreadCount(actor);
  }

  /** Static path before :id so Nest does not treat "read-all" as a UUID. */
  @Post('read-all')
  markAll(@CurrentUser() actor: AuthUser) {
    return this.notifications.markAllRead(actor);
  }

  @Patch(':id/read')
  markReadPatch(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.markRead(actor, id);
  }

  @Post(':id/read')
  markReadPost(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.markRead(actor, id);
  }

  /** Remove inbox row (open-chat race cleanup). */
  @Delete(':id')
  dismiss(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.dismiss(actor, id);
  }
}
