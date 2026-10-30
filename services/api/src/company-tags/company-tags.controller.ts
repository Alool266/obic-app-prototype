// Made by Dr Ali
// Company tags. Customers receive 403. Naming a tag is SuperAdmin.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
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
import { CompanyTagsService } from './company-tags.service';
import { SaveCompanyTagDto, SetContactTagsDto } from './dto/company-tag.dto';

@ApiTags('company-contact-tags')
@ApiBearerAuth()
@Controller('company-contact-tags')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyTagsController {
  constructor(private readonly tags: CompanyTagsService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.tags.mine(actor);
  }

  @Put('contacts/:contactId')
  setMine(
    @CurrentUser() actor: AuthUser,
    @Param('contactId', ParseUUIDPipe) contactId: string,
    @Body() dto: SetContactTagsDto,
  ) {
    return this.tags.setMine(actor, contactId, dto);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-contact-tags')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyTagsController {
  constructor(private readonly tags: CompanyTagsService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.tags.board(actor);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveCompanyTagDto) {
    return this.tags.create(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveCompanyTagDto,
  ) {
    return this.tags.update(actor, id, dto);
  }

  @Put('contacts/:contactId')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  setAdmin(
    @CurrentUser() actor: AuthUser,
    @Param('contactId', ParseUUIDPipe) contactId: string,
    @Body() dto: SetContactTagsDto,
  ) {
    return this.tags.setAdmin(actor, contactId, dto);
  }
}
