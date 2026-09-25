// Made by Dr Ali
// Customer submit + staff review for app bug reports.

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
import { IsArray, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { BugReportStatus } from './bug-report.entity';
import { BugReportsService } from './bug-reports.service';

class CreateBugReportDto {
  @IsString()
  @MinLength(5)
  @MaxLength(4000)
  description!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];
}

class UpdateBugReportDto {
  @IsIn(Object.values(BugReportStatus))
  status!: BugReportStatus;
}

@ApiTags('bug-reports')
@ApiBearerAuth()
@Controller()
export class BugReportsController {
  constructor(private readonly bugs: BugReportsService) {}

  @Post('bug-reports')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Submit an app bug report (customer)' })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateBugReportDto) {
    return this.bugs.create(actor, dto);
  }

  @Get('bug-reports/mine')
  @UseGuards(JwtAuthGuard)
  listMine(@CurrentUser() actor: AuthUser) {
    return this.bugs.listMine(actor);
  }

  @Get('admin/bug-reports')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  @ApiOperation({ summary: 'Staff: list bug reports' })
  listStaff(@CurrentUser() actor: AuthUser) {
    return this.bugs.listForStaff(actor);
  }

  @Get('admin/bug-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  getOne(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.bugs.getOne(actor, id);
  }

  @Patch('admin/bug-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.Employee, UserRole.SuperAdmin)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBugReportDto,
  ) {
    return this.bugs.updateStatus(actor, id, dto.status);
  }
}
