// Made by Dr Ali
// Customer handover. Customers receive 403. Only SuperAdmin can move contacts.

import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyHandoversService } from './company-handovers.service';
import { CreateHandoverDto } from './dto/company-handover.dto';

@ApiTags('company-handovers')
@ApiBearerAuth()
@Controller('company-handovers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyHandoversController {
  constructor(private readonly handovers: CompanyHandoversService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.handovers.mine(actor);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-handovers')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyHandoversController {
  constructor(private readonly handovers: CompanyHandoversService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser, @Query('fromUserId') fromUserId?: string) {
    return this.handovers.board(actor, fromUserId);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateHandoverDto) {
    return this.handovers.create(actor, dto);
  }
}
