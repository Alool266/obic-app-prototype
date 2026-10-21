// Made by Dr Ali
// Internal company mail. Customers receive 403. Messages stay inside OBIC.

import { Body, Controller, Get, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyMailService } from './company-mail.service';
import { SendCompanyMailDto } from './dto/company-mail.dto';

@ApiTags('company-mail')
@ApiBearerAuth()
@Controller('company-mail')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyMailController {
  constructor(private readonly mail: CompanyMailService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.mail.mine(actor);
  }

  @Post()
  send(@CurrentUser() actor: AuthUser, @Body() dto: SendCompanyMailDto) {
    return this.mail.send(actor, dto);
  }

  @Post(':id/read')
  read(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.mail.markRead(actor, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-mail')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyMailController {
  constructor(private readonly mail: CompanyMailService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.mail.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  send(@CurrentUser() actor: AuthUser, @Body() dto: SendCompanyMailDto) {
    return this.mail.sendAdmin(actor, dto);
  }
}
