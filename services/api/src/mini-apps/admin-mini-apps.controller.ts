// Made by Dr Ali
// SuperAdmin review queue. Social login cannot create this role.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RejectMiniAppDto } from './dto/mini-app.dto';
import { MiniAppsService } from './mini-apps.service';

@ApiTags('admin-mini-apps')
@ApiBearerAuth()
@Controller('admin/mini-apps')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminMiniAppsController {
  constructor(private readonly miniApps: MiniAppsService) {}

  @Get()
  @ApiOperation({ summary: 'SuperAdmin: mini app review queue' })
  list(@CurrentUser() actor: AuthUser) {
    return this.miniApps.listForSuperAdmin(actor);
  }

  @Get(':id')
  @ApiOperation({ summary: 'SuperAdmin: one mini app submission' })
  getOne(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.miniApps.getForSuperAdmin(actor, id);
  }

  @Post(':id/approve')
  @ApiOperation({ summary: 'SuperAdmin: approve a pending mini app' })
  approve(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.miniApps.review(actor, id, 'approve');
  }

  @Post(':id/reject')
  @ApiOperation({ summary: 'SuperAdmin: reject a pending mini app with a reason' })
  reject(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectMiniAppDto,
  ) {
    return this.miniApps.review(actor, id, 'reject', dto.reason);
  }

  @Post(':id/disable')
  @ApiOperation({ summary: 'SuperAdmin: kill switch for an approved mini app' })
  disable(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.miniApps.review(actor, id, 'disable');
  }

  @Post(':id/preview')
  @ApiOperation({ summary: 'SuperAdmin: open a pending or approved hosted package' })
  preview(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.miniApps.previewForSuperAdmin(actor, id);
  }
}
