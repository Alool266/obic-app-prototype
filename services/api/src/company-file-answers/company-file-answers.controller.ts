// Made by Dr Ali
// Company file answers. Customers receive 403. Catalog grounding stays off.

import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CompanyFileAnswersService } from './company-file-answers.service';
import { AskCompanyFilesDto } from './dto/company-file-answer.dto';

@ApiTags('company-file-answers')
@ApiBearerAuth()
@Controller('company-file-answers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyFileAnswersController {
  constructor(private readonly answers: CompanyFileAnswersService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.answers.mine(actor);
  }

  @Post()
  ask(@CurrentUser() actor: AuthUser, @Body() dto: AskCompanyFilesDto) {
    return this.answers.ask(actor, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-file-answers')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyFileAnswersController {
  constructor(private readonly answers: CompanyFileAnswersService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.answers.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  ask(@CurrentUser() actor: AuthUser, @Body() dto: AskCompanyFilesDto) {
    return this.answers.askAdmin(actor, dto);
  }
}
