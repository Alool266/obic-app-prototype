// Made by Dr Ali
// Shared documents. Customers receive 403. SuperAdmin names them. Staff update the text.

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
import { CompanyDocumentsService } from './company-documents.service';
import { SaveDocumentBodyDto, SaveDocumentDto } from './dto/company-document.dto';

@ApiTags('company-documents')
@ApiBearerAuth()
@Controller('company-documents')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyDocumentsController {
  constructor(private readonly documents: CompanyDocumentsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.documents.mine(actor);
  }

  @Get(':id')
  one(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.documents.one(actor, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveDocumentBodyDto,
  ) {
    return this.documents.updateBody(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-documents')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyDocumentsController {
  constructor(private readonly documents: CompanyDocumentsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.documents.board(actor);
  }

  @Get(':id')
  one(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.documents.adminOne(actor, id);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveDocumentDto) {
    return this.documents.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveDocumentDto,
  ) {
    return this.documents.saveAdmin(actor, dto, id);
  }
}
