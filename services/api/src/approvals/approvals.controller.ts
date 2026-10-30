// Made by Dr Ali
// Staff approvals. Customers receive 403.

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
import { ApprovalsService } from './approvals.service';
import {
  CreateApprovalTemplateDto,
  DecideApprovalDto,
  OpenApprovalDto,
  UpdateApprovalTemplateDto,
} from './dto/approval.dto';

@ApiTags('approvals')
@ApiBearerAuth()
@Controller('approvals')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class ApprovalsController {
  constructor(private readonly approvals: ApprovalsService) {}

  @Get('templates')
  templates(@CurrentUser() actor: AuthUser) {
    return this.approvals.listTemplates(actor);
  }

  @Get()
  list(@CurrentUser() actor: AuthUser) {
    return this.approvals.listRequests(actor);
  }

  @Post()
  open(@CurrentUser() actor: AuthUser, @Body() dto: OpenApprovalDto) {
    return this.approvals.openRequest(actor, dto);
  }

  @Post(':id/decide')
  decide(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: DecideApprovalDto,
  ) {
    return this.approvals.decide(actor, id, dto);
  }

  @Post(':id/cancel')
  cancel(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.approvals.cancel(actor, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/approval-templates')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.SuperAdmin)
export class AdminApprovalTemplatesController {
  constructor(private readonly approvals: ApprovalsService) {}

  @Post()
  @UseGuards(AdminTotpStepUpGuard)
  create(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateApprovalTemplateDto,
  ) {
    return this.approvals.createTemplate(actor, dto);
  }

  @Patch(':id')
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateApprovalTemplateDto,
  ) {
    return this.approvals.updateTemplate(actor, id, dto);
  }
}
