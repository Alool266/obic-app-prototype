// Made by Dr Ali
// Shared spreadsheets. Customers receive 403. SuperAdmin names them. Staff edit the cells.

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
import { CompanySpreadsheetsService } from './company-spreadsheets.service';
import { SaveSheetDto, SaveSheetGridDto } from './dto/company-spreadsheet.dto';

@ApiTags('company-spreadsheets')
@ApiBearerAuth()
@Controller('company-spreadsheets')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanySpreadsheetsController {
  constructor(private readonly sheets: CompanySpreadsheetsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.sheets.mine(actor);
  }

  @Get(':id')
  one(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.sheets.one(actor, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveSheetGridDto,
  ) {
    return this.sheets.updateGrid(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-spreadsheets')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanySpreadsheetsController {
  constructor(private readonly sheets: CompanySpreadsheetsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.sheets.board(actor);
  }

  @Get(':id')
  one(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.sheets.adminOne(actor, id);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveSheetDto) {
    return this.sheets.saveAdmin(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveSheetDto,
  ) {
    return this.sheets.saveAdmin(actor, dto, id);
  }
}
