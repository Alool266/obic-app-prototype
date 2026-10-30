// Made by Dr Ali
// Customer package upload, own list, public approved catalog, and hosted files.
// Responses never include auth tokens, email, phone, or an external start URL.

import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateMiniAppDto } from './dto/mini-app.dto';
import {
  MINI_APP_PACKAGE_MAX_BYTES,
  packageFilePathFromUrl,
} from './mini-app-package';
import { MiniAppsService } from './mini-apps.service';

@ApiTags('mini-apps')
@Controller('mini-apps')
export class MiniAppsController {
  constructor(private readonly miniApps: MiniAppsService) {}

  @Post()
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('package', {
      storage: memoryStorage(),
      limits: { fileSize: MINI_APP_PACKAGE_MAX_BYTES },
    }),
  )
  @ApiOperation({ summary: 'Upload a mini-app zip (status starts as pending)' })
  create(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateMiniAppDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Choose a .zip package');
    }
    return this.miniApps.submit(actor, {
      name: dto.name,
      description: dto.description,
      iconUrl: dto.iconUrl,
      zip: file.buffer,
    });
  }

  @Get('mine')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'List the signed-in user’s mini app submissions' })
  listMine(@CurrentUser() actor: AuthUser) {
    return this.miniApps.listMine(actor);
  }

  @Get()
  @ApiOperation({
    summary: 'Public catalog: approved hosted packages that are not disabled',
  })
  listPublic() {
    return this.miniApps.listPublic();
  }

  @Get('first-party-flags')
  @ApiOperation({
    summary: 'First-party mini-app enablement (Notes/Docs/hubs) for the shelf',
  })
  firstPartyFlags() {
    return this.miniApps.listFirstPartyFlags();
  }

  @Get(':id/files/*path')
  @ApiOperation({ summary: 'Hosted package file. Approved packages only.' })
  async approvedFile(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const rel = packageFilePathFromUrl(
      req.originalUrl || req.url,
      `/v1/mini-apps/${id}/files/`,
    );
    if (!rel) {
      res.status(404).send('Not found');
      return;
    }
    try {
      const file = await this.miniApps.readApprovedFile(id, rel);
      sendPackageFile(res, file.data, file.mime, true);
    } catch {
      res.status(404).send('Not found');
    }
  }

  @Get(':id/preview/:ticket/*path')
  @ApiOperation({ summary: 'SuperAdmin preview of a pending package' })
  async previewFile(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('ticket') ticket: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const rel = packageFilePathFromUrl(
      req.originalUrl || req.url,
      `/v1/mini-apps/${id}/preview/${ticket}/`,
    );
    if (!rel) {
      res.status(404).send('Not found');
      return;
    }
    try {
      const file = await this.miniApps.readPreviewFile(id, ticket, rel);
      sendPackageFile(res, file.data, file.mime, false);
    } catch {
      res.status(404).send('Not found');
    }
  }
}

function sendPackageFile(
  res: Response,
  data: Buffer,
  mime: string,
  approved: boolean,
) {
  res.setHeader('Content-Type', mime);
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Content-Disposition', 'inline');
  res.setHeader(
    'Cache-Control',
    approved ? 'public, max-age=60' : 'private, no-store',
  );
  res.status(200).send(data);
}
