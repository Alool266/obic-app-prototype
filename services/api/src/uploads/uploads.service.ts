// Made by Dr Ali
// Persist uploads in Postgres so Moments/chat media survives ephemeral disk.
//
// Trial durability:
// - ≤12MB → Postgres bytea (uploaded_files) + disk cache — survives Render redeploy
// - >12MB → disk only (ephemeral on free trial; use S3/GCS for production video)

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { mkdirSync, writeFileSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { Repository } from 'typeorm';
import { UploadedFile } from './uploaded-file.entity';

export const UPLOAD_ROOT = join(process.cwd(), 'uploads');

/** Photos fit; large videos stay disk-only (documented trial limit). */
const DB_PERSIST_MAX_BYTES = 12 * 1024 * 1024;

@Injectable()
export class UploadsService {
  private readonly log = new Logger(UploadsService.name);

  constructor(
    @InjectRepository(UploadedFile)
    private readonly files: Repository<UploadedFile>,
  ) {
    try {
      mkdirSync(UPLOAD_ROOT, { recursive: true });
    } catch {
      /* ignore */
    }
  }

  async persist(
    opts: {
      id: string;
      filename: string;
      originalName?: string | null;
      mime: string;
      buffer: Buffer;
      uploaderId?: string | null;
    },
  ): Promise<{ storedInDb: boolean }> {
    const { id, filename, originalName, mime, buffer, uploaderId } = opts;

    // Always warm local disk for fast local/dev serves.
    try {
      writeFileSync(join(UPLOAD_ROOT, filename), buffer);
    } catch (e) {
      this.log.warn(`Disk write failed for ${filename}: ${String(e)}`);
    }

    if (buffer.length > DB_PERSIST_MAX_BYTES) {
      this.log.warn(
        `Skip DB persist for ${filename} (${buffer.length} bytes > ${DB_PERSIST_MAX_BYTES})`,
      );
      return { storedInDb: false };
    }

    await this.files.save(
      this.files.create({
        id,
        filename,
        originalName: originalName ?? null,
        mime: mime || 'application/octet-stream',
        size: buffer.length,
        data: buffer,
        uploaderId: uploaderId ?? null,
      }),
    );
    return { storedInDb: true };
  }

  async readBuffer(filename: string): Promise<{
    buffer: Buffer;
    mime: string;
  } | null> {
    const safe = filename.replace(/[/\\]/g, '');
    if (!safe || safe !== filename) return null;

    const disk = join(UPLOAD_ROOT, safe);
    if (existsSync(disk)) {
      return {
        buffer: readFileSync(disk),
        mime: mimeFromName(safe),
      };
    }

    const row = await this.files.findOne({ where: { filename: safe } });
    if (!row) return null;

    // Rehydrate disk cache after redeploy.
    try {
      writeFileSync(disk, row.data);
    } catch {
      /* ignore */
    }

    return { buffer: row.data, mime: row.mime || mimeFromName(safe) };
  }
}

function mimeFromName(name: string): string {
  const lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}
