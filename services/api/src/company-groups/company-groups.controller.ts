// Made by Dr Ali
// Customer groups. Customers receive 403. Desk writes are SuperAdmin.

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
import { CompanyGroupsService } from './company-groups.service';
import { AdminSaveCompanyGroupDto, SaveCompanyGroupDto } from './dto/company-group.dto';

@ApiTags('company-contact-groups')
@ApiBearerAuth()
@Controller('company-contact-groups')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyGroupsController {
  constructor(private readonly groups: CompanyGroupsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.groups.mine(actor);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCompanyGroupDto) {
    return this.groups.createMine(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCompanyGroupDto,
  ) {
    return this.groups.updateMine(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-contact-groups')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyGroupsController {
  constructor(private readonly groups: CompanyGroupsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.groups.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: AdminSaveCompanyGroupDto) {
    return this.groups.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminSaveCompanyGroupDto,
  ) {
    return this.groups.saveAdmin(actor, dto, id);
  }
}
