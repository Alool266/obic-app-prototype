// Made by Dr Ali
// Customer/staff: file a report. SuperAdmin queue lives under /v1/admin/moderation.

import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateReportDto } from './dto/moderation.dto';
import { ModerationService } from './moderation.service';

@ApiTags('moderation')
@ApiBearerAuth()
@Controller('moderation')
@UseGuards(JwtAuthGuard)
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Post('reports')
  @ApiOperation({
    summary: 'Report a message, moment, comment, or thread',
    description:
      'JWT required. Chat targets: reporter must be a participant. Server stores the queue; customers never see admin.',
  })
  createReport(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateReportDto,
  ) {
    return this.moderation.createUserReport(actor, {
      targetType: dto.targetType,
      targetId: dto.targetId,
      reason: dto.reason,
    });
  }
}
