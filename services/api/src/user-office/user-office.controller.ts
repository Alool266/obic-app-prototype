// Made by Dr Ali
// /v1/user-office — personal Notes / Docs / Sheets / PDF.

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  CreateUserOfficeDto,
  ShareUserOfficeDto,
  UpdateUserOfficeDto,
} from './dto/user-office.dto';
import { UserOfficeService } from './user-office.service';

@ApiTags('user-office')
@ApiBearerAuth()
@Controller('user-office')
@UseGuards(JwtAuthGuard)
export class UserOfficeController {
  constructor(private readonly office: UserOfficeService) {}

  @Get()
  list(@CurrentUser() actor: AuthUser, @Query('kind') kind?: string) {
    return this.office.list(actor, kind);
  }

  @Get(':id')
  one(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.office.one(actor, id);
  }

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateUserOfficeDto) {
    return this.office.create(actor, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserOfficeDto,
  ) {
    return this.office.update(actor, id, dto);
  }

  @Put(':id/share')
  share(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ShareUserOfficeDto,
  ) {
    return this.office.share(actor, id, dto);
  }

  @Delete(':id')
  remove(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.office.remove(actor, id);
  }
}
