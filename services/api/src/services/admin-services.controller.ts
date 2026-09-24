// Made by Dr Ali
// SuperAdmin catalog CRUD — /v1/admin/services

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
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import {
  AdminCreateServiceDto,
  AdminUpdateServiceDto,
} from './dto/admin-service.dto';
import { ServicesService } from './services.service';

@ApiTags('admin-services')
@ApiBearerAuth()
@Controller('admin/services')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get()
  @ApiOperation({ summary: 'List all catalog services (SuperAdmin)' })
  list() {
    return this.servicesService.listAllAdmin();
  }

  @Post()
  @ApiOperation({ summary: 'Create catalog service (SuperAdmin)' })
  create(@Body() dto: AdminCreateServiceDto) {
    return this.servicesService.createAdmin(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update catalog service (SuperAdmin)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminUpdateServiceDto,
  ) {
    return this.servicesService.updateAdmin(id, dto);
  }
}
