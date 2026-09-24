// Made by Dr Ali
// Public offers browse + staff admin CRUD under /v1/admin/offers.

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  CreateOfferDto,
  UpdateOfferDto,
} from './dto/offer.dto';
import { filtersFromQuery, OffersService } from './offers.service';

@ApiTags('offers')
@Controller('offers')
export class OffersController {
  constructor(private readonly offers: OffersService) {}

  @Get()
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({
    summary: 'List published offers',
    description:
      'Customers see published, not sold-out, not expired offers. Filter with kind/type, q, city.',
  })
  @ApiQuery({ name: 'kind', required: false, description: 'Offer type slug (hotels, flights, …)' })
  @ApiQuery({ name: 'type', required: false, description: 'Alias of kind' })
  @ApiQuery({ name: 'q', required: false, description: 'Search title, body, location' })
  @ApiQuery({ name: 'city', required: false, description: 'Match location_label / attributes' })
  @ApiOkResponse({ description: '{ items: Offer[] }' })
  list(
    @Query('kind') kind?: string,
    @Query('type') type?: string,
    @Query('q') q?: string,
    @Query('city') city?: string,
  ) {
    return this.offers.listPublished(filtersFromQuery({ kind, type, q, city }));
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one published offer' })
  one(@Param('id', ParseUUIDPipe) id: string) {
    return this.offers.getPublished(id);
  }
}

@ApiTags('admin-offers')
@ApiBearerAuth()
@Controller('admin/offers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminOffersController {
  constructor(private readonly offers: OffersService) {}

  @Get()
  @ApiOperation({
    summary: 'Staff list offers',
    description:
      'Requires canManageOffers (SuperAdmin or offersAccess). Same filters as public list.',
  })
  @ApiQuery({ name: 'kind', required: false })
  @ApiQuery({ name: 'type', required: false })
  @ApiQuery({ name: 'q', required: false })
  @ApiQuery({ name: 'city', required: false })
  list(
    @CurrentUser() actor: AuthUser,
    @Query('kind') kind?: string,
    @Query('type') type?: string,
    @Query('q') q?: string,
    @Query('city') city?: string,
  ) {
    return this.offers.listForStaff(actor, filtersFromQuery({ kind, type, q, city }));
  }

  @Post()
  @ApiOperation({ summary: 'Create offer (staff)' })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateOfferDto) {
    return this.offers.create(actor, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update offer (staff / owner)' })
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateOfferDto,
  ) {
    return this.offers.update(actor, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete offer (staff / owner)' })
  remove(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.offers.remove(actor, id);
  }
}
