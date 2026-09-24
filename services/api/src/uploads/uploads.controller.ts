// Made by Dr Ali
// Multipart upload — images, videos, files for Moments / avatars.
// Bytes also stored in Postgres so trial redeploys do not 404 media.

import {
  BadRequestException,
  Controller,
  Post,
  Req,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import type { Request } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UploadsService } from './uploads.service';

const ALLOWED = new Set([
  // images
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.heic',
  // video
  '.mp4',
  '.mov',
  '.m4v',
  '.webm',
  // docs / misc
  '.pdf',
  '.doc',
  '.docx',
  '.xls',
  '.xlsx',
  '.ppt',
  '.pptx',
  '.txt',
  '.zip',
  '.rar',
]);

function kindFromExt(ext: string): 'image' | 'video' | 'file' {
  const e = ext.toLowerCase();
  if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].includes(e)) {
    return 'image';
  }
  if (['.mp4', '.mov', '.m4v', '.webm'].includes(e)) return 'video';
  return 'file';
}

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FilesInterceptor('files', 9, {
      storage: memoryStorage(),
      limits: { fileSize: 80 * 1024 * 1024 }, // 80MB — videos
      fileFilter: (_req, file, cb) => {
        const ext = extname(file.originalname || '').toLowerCase();
        if (!ALLOWED.has(ext)) {
          return cb(
            new BadRequestException(`File type not allowed: ${ext || 'unknown'}`),
            false,
          );
        }
        cb(null, true);
      },
    }),
  )
  async upload(
    @CurrentUser() actor: AuthUser,
    @UploadedFiles() files: Express.Multer.File[],
    @Req() req: Request,
  ) {
    if (!files?.length) {
      throw new BadRequestException('No files uploaded');
    }

    const proto = (req.headers['x-forwarded-proto'] as string) || req.protocol;
    const host = req.get('host');
    const base = `${proto}://${host}`;

    const items = [];
    for (const f of files) {
      const ext = extname(f.originalname || '').toLowerCase() || '';
      const id = randomUUID();
      const filename = `${id}${ext}`;
      const buffer = f.buffer;
      if (!buffer?.length) {
        throw new BadRequestException('Empty upload');
      }

      await this.uploads.persist({
        id,
        filename,
        originalName: f.originalname || filename,
        mime: f.mimetype || 'application/octet-stream',
        buffer,
        uploaderId: actor.userId,
      });

      items.push({
        kind: kindFromExt(ext),
        url: `${base}/uploads/${filename}`,
        name: f.originalname || filename,
        mime: f.mimetype,
        size: f.size,
      });
    }

    return { items };
  }
}
