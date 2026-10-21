// Made by Dr Ali
// Staff work reports. Customers receive 403. The desk is SuperAdmin and Internal Ops.

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
import { SubmitReportDto, UpdateReportReviewersDto } from './dto/report.dto';
import { ReportsService } from './reports.service';

@ApiTags('reports')
@ApiBearerAuth()
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get()
  home(@CurrentUser() actor: AuthUser) {
    return this.reports.home(actor);
  }

  @Post()
  submit(@CurrentUser() actor: AuthUser, @Body() dto: SubmitReportDto) {
    return this.reports.submit(actor, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/reports')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser, @Query('kind') kind?: string) {
    return this.reports.board(actor, kind);
  }

  @Patch('reviewers')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  updateReviewers(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateReportReviewersDto,
  ) {
    return this.reports.updateReviewers(actor, dto);
  }
}
