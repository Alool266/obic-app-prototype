// Made by Dr Ali
// Richer meetings. Customers receive 403. The app does not start a call.

import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyMeetingsService } from './company-meetings.service';
import { SaveMeetingDto } from './dto/company-meeting.dto';

@ApiTags('company-meetings')
@ApiBearerAuth()
@Controller('company-meetings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyMeetingsController {
  constructor(private readonly meetings: CompanyMeetingsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.meetings.mine(actor);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveMeetingDto) {
    return this.meetings.saveMine(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveMeetingDto,
  ) {
    return this.meetings.saveMine(actor, dto, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-meetings')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyMeetingsController {
  constructor(private readonly meetings: CompanyMeetingsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.meetings.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveMeetingDto) {
    return this.meetings.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveMeetingDto,
  ) {
    return this.meetings.saveAdmin(actor, dto, id);
  }
}
