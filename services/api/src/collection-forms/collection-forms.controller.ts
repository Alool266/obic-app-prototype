// Made by Dr Ali
// Collection forms. Customers receive 403. The desk is SuperAdmin and Internal Ops.

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
import { CollectionFormsService } from './collection-forms.service';
import {
  SaveCollectionFormDto,
  SubmitCollectionFormDto,
} from './dto/collection-form.dto';

@ApiTags('collection-forms')
@ApiBearerAuth()
@Controller('collection-forms')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CollectionFormsController {
  constructor(private readonly forms: CollectionFormsService) {}

  @Get()
  home(@CurrentUser() actor: AuthUser) {
    return this.forms.home(actor);
  }

  @Post(':id')
  submit(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SubmitCollectionFormDto,
  ) {
    return this.forms.submit(actor, id, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/collection-forms')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCollectionFormsController {
  constructor(private readonly forms: CollectionFormsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.forms.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCollectionFormDto) {
    return this.forms.create(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCollectionFormDto,
  ) {
    return this.forms.update(actor, id, dto);
  }
}
