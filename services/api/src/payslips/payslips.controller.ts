// Made by Dr Ali
// Staff payslips. Customers receive 403. Writes are SuperAdmin. The desk can read.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
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
import { SavePayslipDto } from './dto/payslip.dto';
import { PayslipsService } from './payslips.service';

@ApiTags('payslips')
@ApiBearerAuth()
@Controller('payslips')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class PayslipsController {
  constructor(private readonly payslips: PayslipsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.payslips.mine(actor);
  }

  @Post(':id/acknowledge')
  acknowledge(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.payslips.acknowledge(actor, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/payslips')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminPayslipsController {
  constructor(private readonly payslips: PayslipsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.payslips.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  save(@CurrentUser() actor: AuthUser, @Body() dto: SavePayslipDto) {
    return this.payslips.save(actor, dto);
  }
}
