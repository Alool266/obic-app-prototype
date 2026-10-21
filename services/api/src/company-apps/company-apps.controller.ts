// Made by Dr Ali
// Company web tools. Customers receive 403.

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
import { CompanyAppsService } from './company-apps.service';
import { SaveCompanyAppDto } from './dto/company-app.dto';

@ApiTags('company-apps')
@ApiBearerAuth()
@Controller('company-apps')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyAppsController {
  constructor(private readonly apps: CompanyAppsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.apps.mine(actor);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-apps')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyAppsController {
  constructor(private readonly apps: CompanyAppsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.apps.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCompanyAppDto) {
    return this.apps.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCompanyAppDto,
  ) {
    return this.apps.saveAdmin(actor, dto, id);
  }
}
