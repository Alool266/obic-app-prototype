// Made by Dr Ali
// Company calendar. Customers receive 403. The app does not send invitations.

import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyCalendarService } from './company-calendar.service';
import { SaveCalendarEventDto } from './dto/company-calendar.dto';

@ApiTags('company-calendar')
@ApiBearerAuth()
@Controller('company-calendar')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyCalendarController {
  constructor(private readonly calendar: CompanyCalendarService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser, @Query('from') from?: string, @Query('to') to?: string) {
    return this.calendar.mine(actor, from, to);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCalendarEventDto) {
    return this.calendar.createMine(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCalendarEventDto,
  ) {
    return this.calendar.updateMine(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-calendar')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyCalendarController {
  constructor(private readonly calendar: CompanyCalendarService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser, @Query('from') from?: string, @Query('to') to?: string) {
    return this.calendar.board(actor, from, to);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCalendarEventDto) {
    return this.calendar.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCalendarEventDto,
  ) {
    return this.calendar.saveAdmin(actor, dto, id);
  }
}
