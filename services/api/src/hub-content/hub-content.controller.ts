// Made by Dr Ali
// Public hub content + Admin publish toggles.

import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { HubContentService } from './hub-content.service';

@ApiTags('hub-content')
@Controller('hub-content')
export class HubContentController {
  constructor(private readonly hubs: HubContentService) {}

  @Get()
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'Published guides / places / deals for hubs' })
  @ApiOkResponse({ description: '{ guides, places, deals, categories }' })
  list(@Query('hub') hub?: string, @Query('city') city?: string) {
    return this.hubs.bundle(hub, city);
  }
}

@ApiTags('admin-hub-content')
@Controller('admin/hub-content')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminHubContentController {
  constructor(private readonly hubs: HubContentService) {}

  @Get()
  @ApiOperation({ summary: 'List all hub content (incl. unpublished)' })
  list() {
    return this.hubs.adminList();
  }

  @Patch('publish')
  @ApiOperation({ summary: 'Toggle published flag on guide/place/deal' })
  publish(
    @Body()
    body: {
      kind: 'guides' | 'places' | 'deals';
      id: string;
      published: boolean;
    },
  ) {
    return this.hubs.setPublished(body.kind, body.id, !!body.published);
  }

  @Post('guides')
  @Roles(UserRole.SuperAdmin)
  @ApiOperation({ summary: 'Upsert a guide (in-memory until DB migration)' })
  upsertGuide(@Body() body: Record<string, unknown>) {
    const id = String(body.id || '').trim();
    if (!id) return { ok: false, message: 'id_required' };
    return this.hubs.upsertGuide({ ...body, id } as never);
  }
}
