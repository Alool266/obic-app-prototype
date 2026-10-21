// Made by Dr Ali
// Company contacts. Customers receive 403. Desk writes are SuperAdmin.

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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyContactsService } from './company-contacts.service';
import {
  AdminSaveCompanyContactDto,
  SaveCompanyContactDto,
} from './dto/company-contact.dto';

@ApiTags('company-contacts')
@ApiBearerAuth()
@Controller('company-contacts')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyContactsController {
  constructor(private readonly contacts: CompanyContactsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser, @Query('q') q?: string) {
    return this.contacts.mine(actor, q);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCompanyContactDto) {
    return this.contacts.createMine(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCompanyContactDto,
  ) {
    return this.contacts.updateMine(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-contacts')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyContactsController {
  constructor(private readonly contacts: CompanyContactsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser, @Query('q') q?: string) {
    return this.contacts.board(actor, q);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: AdminSaveCompanyContactDto) {
    return this.contacts.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminSaveCompanyContactDto,
  ) {
    return this.contacts.saveAdmin(actor, dto, id);
  }
}
