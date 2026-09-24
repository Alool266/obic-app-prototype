// Made by Dr Ali
// SuperAdmin TOTP — enroll / confirm / disable / status.

import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  TotpConfirmDto,
  TotpDisableDto,
} from './dto/admin-totp.dto';
import { AdminTotpService } from './admin-totp.service';

@ApiTags('admin-totp')
@ApiBearerAuth()
@Controller('admin/totp')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminTotpController {
  constructor(private readonly totpService: AdminTotpService) {}

  @Get('status')
  @ApiOperation({ summary: 'TOTP enrollment status (SuperAdmin)' })
  status(@CurrentUser() user: AuthUser) {
    return this.totpService.status(user.userId);
  }

  @Post('enroll')
  @ApiOperation({ summary: 'Start TOTP enroll — returns QR otpauth URL + secret' })
  enroll(@CurrentUser() user: AuthUser) {
    return this.totpService.enroll(user.userId);
  }

  @Post('confirm')
  @ApiOperation({ summary: 'Confirm enroll with first 6-digit code' })
  confirm(@CurrentUser() user: AuthUser, @Body() dto: TotpConfirmDto) {
    return this.totpService.confirm(user.userId, dto.code);
  }

  @Post('disable')
  @ApiOperation({ summary: 'Disable TOTP — password + current code' })
  disable(@CurrentUser() user: AuthUser, @Body() dto: TotpDisableDto) {
    return this.totpService.disable(user.userId, dto.password, dto.code);
  }
}
