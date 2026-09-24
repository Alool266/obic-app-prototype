// Made by Dr Ali
// /v1/admin — Employee + SuperAdmin only. Role always re-checked from DB via RolesGuard.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { AdminService } from './admin.service';
import {
  AdminAiSettingsDto,
  AdminCreateStaffDto,
  AdminUpdateOrderDto,
  AdminUpdateStaffProfileDto,
  AdminUpdateStaffRoleDto,
} from './dto/admin.dto';

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('me')
  @ApiOperation({
    summary: 'Staff session profile',
    description: 'Employee + SuperAdmin only. Customer JWT receives 403.',
  })
  me(@CurrentUser() actor: AuthUser) {
    return this.admin.me(actor);
  }

  @Get('dashboard')
  dashboard(@CurrentUser() actor: AuthUser) {
    return this.admin.dashboard(actor);
  }

  @Get('orders')
  listOrders(@CurrentUser() actor: AuthUser) {
    return this.admin.listOrders(actor);
  }

  @Patch('orders/:id')
  updateOrder(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminUpdateOrderDto,
  ) {
    return this.admin.updateOrder(actor, id, dto);
  }

  @Get('orders/:id/chat')
  openOrderChat(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.admin.openOrderChat(actor, id);
  }

  /** Staff directory — SuperAdmin (full) or Form2 reassign roles (Employees). */
  @Get('staff')
  listStaff(@CurrentUser() actor: AuthUser) {
    return this.admin.listStaff(actor);
  }

  /** Form2 rule 5 — SuperAdmin creates Employee; production phones/emails later. */
  @Post('staff')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  @ApiOperation({
    summary: 'Create staff (Employee)',
    description:
      'SuperAdmin only. Email or phone required. Real production contacts can be filled later via profile edit.',
  })
  createStaff(
    @CurrentUser() actor: AuthUser,
    @Body() dto: AdminCreateStaffDto,
  ) {
    return this.admin.createStaff(actor, dto);
  }

  @Patch('staff/:id/role')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  updateStaffRole(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminUpdateStaffRoleDto,
  ) {
    return this.admin.updateStaffRole(actor, id, dto);
  }

  @Patch('staff/:id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  updateStaffProfile(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminUpdateStaffProfileDto,
  ) {
    return this.admin.updateStaffProfile(actor, id, dto);
  }

  @Get('oversight/chats')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({
    summary: 'Chat oversight list',
    description:
      'SuperAdmin — Support/order/group (+ staff directs). Optional friend DMs via includeFriends. Audited.',
  })
  listEmployeeChats(
    @CurrentUser() actor: AuthUser,
    @Query('kind') kind?: string,
    @Query('q') q?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('includeFriends') includeFriends?: string,
  ) {
    return this.admin.listEmployeeChats(actor, {
      kind,
      q,
      from,
      to,
      includeFriends:
        includeFriends === '1' ||
        includeFriends === 'true' ||
        includeFriends === 'yes',
    });
  }

  @Get('oversight/chats/:id/messages')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({
    summary: 'Chat oversight transcript',
    description:
      'SuperAdmin — full history. Friend DMs read-only. Audited.',
  })
  transcript(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.admin.readTranscript(actor, id);
  }

  @Post('oversight/chats/:id/join')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({
    summary: 'Join Support/order/group chat',
    description:
      'SuperAdmin becomes a participant. Friend DMs refuse join. Audited + optional notify.',
  })
  joinChat(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.admin.joinOversightChat(actor, id);
  }

  @Get('audit')
  @Roles(UserRole.SuperAdmin)
  audit(
    @CurrentUser() actor: AuthUser,
    @Query('limit') limit?: string,
  ) {
    const n = limit ? Number(limit) : 100;
    return this.admin.listAudit(actor, Number.isFinite(n) ? n : 100);
  }

  @Get('ai-settings')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({
    summary: 'AI auto-reply settings',
    description:
      'SuperAdmin only. Global kill-switch for support/order AI auto-reply (DB).',
  })
  getAiSettings(@CurrentUser() actor: AuthUser) {
    return this.admin.getAiSettings(actor);
  }

  @Patch('ai-settings')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({
    summary: 'Update AI auto-reply settings',
    description: 'SuperAdmin only. Audited. Per-thread toggle remains on chat API.',
  })
  setAiSettings(
    @CurrentUser() actor: AuthUser,
    @Body() dto: AdminAiSettingsDto,
  ) {
    return this.admin.setAiSettings(actor, dto);
  }
}
