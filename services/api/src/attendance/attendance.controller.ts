// Made by Dr Ali
// Staff clock-in. Customers receive 403. The desk is SuperAdmin and Internal Ops.

import { Body, Controller, Get, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { AttendanceService } from './attendance.service';
import { PunchDto, UpdateAttendanceRuleDto } from './dto/attendance.dto';

@ApiTags('attendance')
@ApiBearerAuth()
@Controller('attendance')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AttendanceController {
  constructor(private readonly attendance: AttendanceService) {}

  @Get()
  home(@CurrentUser() actor: AuthUser) {
    return this.attendance.home(actor);
  }

  @Post('punch')
  punch(@CurrentUser() actor: AuthUser, @Body() dto: PunchDto) {
    return this.attendance.punch(actor, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/attendance')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminAttendanceController {
  constructor(private readonly attendance: AttendanceService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser, @Query('date') date?: string) {
    return this.attendance.board(actor, date);
  }

  @Patch('rule')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  updateRule(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateAttendanceRuleDto,
  ) {
    return this.attendance.updateRule(actor, dto);
  }
}
