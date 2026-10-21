// Made by Dr Ali
// Company greetings. Customers receive 403. Writes are SuperAdmin.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
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
import { CompanyWelcomesService } from './company-welcomes.service';
import { AssignWelcomeDto, SaveWelcomeDto } from './dto/company-welcome.dto';

@ApiTags('company-welcomes')
@ApiBearerAuth()
@Controller('company-welcomes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyWelcomesController {
  constructor(private readonly welcomes: CompanyWelcomesService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.welcomes.mine(actor);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-welcomes')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyWelcomesController {
  constructor(private readonly welcomes: CompanyWelcomesService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.welcomes.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveWelcomeDto) {
    return this.welcomes.create(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveWelcomeDto,
  ) {
    return this.welcomes.update(actor, id, dto);
  }

  @Put('assignments')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  assign(@CurrentUser() actor: AuthUser, @Body() dto: AssignWelcomeDto) {
    return this.welcomes.assign(actor, dto);
  }
}
