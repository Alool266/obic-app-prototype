// Made by Dr Ali
// Staff forms. Customers receive 403. The desk is SuperAdmin and Internal Ops.

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
import { SaveOfficeFormDto, SubmitOfficeFormDto } from './dto/office-form.dto';
import { OfficeFormsService } from './office-forms.service';

@ApiTags('office-forms')
@ApiBearerAuth()
@Controller('office-forms')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class OfficeFormsController {
  constructor(private readonly forms: OfficeFormsService) {}

  @Get()
  home(@CurrentUser() actor: AuthUser) {
    return this.forms.home(actor);
  }

  @Post()
  submit(@CurrentUser() actor: AuthUser, @Body() dto: SubmitOfficeFormDto) {
    return this.forms.submit(actor, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/office-forms')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminOfficeFormsController {
  constructor(private readonly forms: OfficeFormsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.forms.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveOfficeFormDto) {
    return this.forms.create(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveOfficeFormDto,
  ) {
    return this.forms.update(actor, id, dto);
  }
}
