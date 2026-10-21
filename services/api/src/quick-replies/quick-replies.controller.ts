// Made by Dr Ali
// Quick replies. Customers receive 403. Company replies are written by SuperAdmin.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { SaveQuickReplyDto } from './dto/quick-reply.dto';
import { QuickRepliesService } from './quick-replies.service';

@ApiTags('quick-replies')
@ApiBearerAuth()
@Controller('quick-replies')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class QuickRepliesController {
  constructor(private readonly replies: QuickRepliesService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.replies.mine(actor);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveQuickReplyDto) {
    return this.replies.createMine(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveQuickReplyDto,
  ) {
    return this.replies.updateMine(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/quick-replies')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminQuickRepliesController {
  constructor(private readonly replies: QuickRepliesService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.replies.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveQuickReplyDto) {
    return this.replies.createAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveQuickReplyDto,
  ) {
    return this.replies.updateAdmin(actor, id, dto);
  }
}
