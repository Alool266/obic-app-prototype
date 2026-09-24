// Made by Dr Ali
// SuperAdmin-only review queue and banned-word list.

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
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateBannedWordDto, ReviewReportDto } from './dto/moderation.dto';
import { ModerationService } from './moderation.service';

@ApiTags('admin-moderation')
@ApiBearerAuth()
@Controller('admin/moderation')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Get('reports')
  @ApiOperation({ summary: 'Open + recent content reports (SuperAdmin)' })
  listReports(@CurrentUser() actor: AuthUser) {
    return this.moderation.listReports(actor);
  }

  @Patch('reports/:id')
  review(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewReportDto,
  ) {
    return this.moderation.reviewReport(actor, id, dto.status);
  }

  @Get('words')
  listWords(@CurrentUser() actor: AuthUser) {
    return this.moderation.listWords(actor);
  }

  @Post('words')
  addWord(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateBannedWordDto,
  ) {
    return this.moderation.addWord(actor, dto.phrase, dto.category);
  }
}
