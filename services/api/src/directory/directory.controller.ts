// Made by Dr Ali
// Staff directory and the department desk. Customers receive 403.

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  DirectoryService,
  assertDepartmentUpdate,
} from './directory.service';
import { CreateDepartmentDto, UpdateDepartmentDto } from './dto/department.dto';

@ApiTags('directory')
@ApiBearerAuth()
@Controller('directory')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class DirectoryController {
  constructor(private readonly directory: DirectoryService) {}

  @Get()
  @ApiOperation({
    summary: 'Company directory for the signed-in staff member',
    description:
      'Employees see colleagues allowed by each department. Phone and email are included for SuperAdmin only.',
  })
  list(@CurrentUser() actor: AuthUser) {
    return this.directory.listDirectory(actor);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/departments')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminDepartmentsController {
  constructor(private readonly directory: DirectoryService) {}

  @Get()
  list(@CurrentUser() actor: AuthUser) {
    return this.directory.listDepartments(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateDepartmentDto) {
    return this.directory.createDepartment(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDepartmentDto,
  ) {
    assertDepartmentUpdate(dto);
    return this.directory.updateDepartment(actor, id, dto);
  }

  @Delete(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  remove(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.directory.deleteDepartment(actor, id);
  }
}
