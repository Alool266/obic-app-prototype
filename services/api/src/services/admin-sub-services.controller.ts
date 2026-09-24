// Made by Dr Ali
// SuperAdmin inner-service CRUD — /v1/admin/service-subs

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
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import {
  AdminCreateSubServiceDto,
  AdminUpdateSubServiceDto,
} from './dto/admin-sub-service.dto';
import { ServicesService } from './services.service';

@ApiTags('admin-service-subs')
@ApiBearerAuth()
@Controller('admin/service-subs')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminSubServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get()
  @ApiOperation({ summary: 'List inner services for a parent (SuperAdmin)' })
  list(@Query('serviceId', ParseUUIDPipe) serviceId: string) {
    return this.servicesService.listSubServicesAdmin(serviceId);
  }

  @Post()
  @ApiOperation({ summary: 'Create inner service (SuperAdmin)' })
  create(@Body() dto: AdminCreateSubServiceDto) {
    return this.servicesService.createSubServiceAdmin(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update inner service (SuperAdmin)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AdminUpdateSubServiceDto,
  ) {
    return this.servicesService.updateSubServiceAdmin(id, dto);
  }
}
