// Made by Dr Ali
// Staff roster. Customers receive 403. Writes are SuperAdmin. The desk can read.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
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
import { RecordJoinDto, RequestLeaveDto } from './dto/roster.dto';
import { RosterService } from './roster.service';

@ApiTags('roster')
@ApiBearerAuth()
@Controller('roster')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class RosterController {
  constructor(private readonly roster: RosterService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.roster.mine(actor);
  }

  @Post('leave')
  requestLeave(@CurrentUser() actor: AuthUser, @Body() dto: RequestLeaveDto) {
    return this.roster.requestLeave(actor, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/roster')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminRosterController {
  constructor(private readonly roster: RosterService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.roster.board(actor);
  }

  @Post('join')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  join(@CurrentUser() actor: AuthUser, @Body() dto: RecordJoinDto) {
    return this.roster.recordJoin(actor, dto);
  }

  @Post(':userId/confirm-leave')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  confirm(
    @CurrentUser() actor: AuthUser,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.roster.confirmLeave(actor, userId);
  }

  @Post(':userId/cancel-leave')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  cancel(
    @CurrentUser() actor: AuthUser,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.roster.cancelLeave(actor, userId);
  }
}
