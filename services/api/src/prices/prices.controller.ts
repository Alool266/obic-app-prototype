// Made by Dr Ali
// /v1/prices — active price list + computed quote (login required).
// /v1/admin/prices — SuperAdmin version management (TOTP step-up on transitions).

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
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreatePriceVersionDto, TransitionPriceDto } from './dto/price.dto';
import { PricesService } from './prices.service';

@ApiTags('prices')
@ApiBearerAuth()
@Controller('prices')
@UseGuards(JwtAuthGuard)
export class PricesController {
  constructor(private readonly prices: PricesService) {}

  @Get('active')
  @ApiOperation({ summary: 'List active prices (optionally by service/city)' })
  active(
    @Query('serviceKey') serviceKey?: string,
    @Query('city') city?: string,
  ) {
    return this.prices.active({ serviceKey, city });
  }

  @Get('quote')
  @ApiOperation({ summary: 'Computed quote from active price versions' })
  quote(
    @Query('serviceKey') serviceKey: string,
    @Query('city') city?: string,
    @Query('nationality') nationality?: string,
  ) {
    return this.prices.quote({ serviceKey, city, nationality });
  }
}

@ApiTags('admin-prices')
@ApiBearerAuth()
@Controller('admin/prices')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminPricesController {
  constructor(private readonly prices: PricesService) {}

  @Get()
  @ApiOperation({ summary: 'List every price version (SuperAdmin)' })
  list() {
    return this.prices.adminList();
  }

  @Post()
  @ApiOperation({ summary: 'Create a Draft price version (SuperAdmin)' })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreatePriceVersionDto) {
    return this.prices.create(actor, dto);
  }

  @Patch(':id/transition')
  @UseGuards(AdminTotpStepUpGuard)
  @ApiOperation({ summary: 'Move a price Draft → Review → Approved → Active → Retired' })
  transition(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TransitionPriceDto,
  ) {
    return this.prices.transition(actor, id, dto);
  }
}
