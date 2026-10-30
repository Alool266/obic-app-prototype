// Made by Dr Ali
// Company drive. Staff open folders. Customers receive 403. Bytes are not public.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  StreamableFile,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertDriveBytes,
  DRIVE_FILES_PER_FOLDER,
  DRIVE_FOLDER_LIMIT,
  driveContentDisposition,
  driveFileParts,
  driveFolderKey,
  driveMime,
  normalizeDriveFolderName,
} from './company-drive';
import { CompanyDriveFile, CompanyDriveFolder } from './company-drive.entities';
import { SaveDriveFolderDto, SetDriveFileActiveDto } from './dto/company-drive.dto';

@Injectable()
export class CompanyDriveService {
  constructor(
    @InjectRepository(CompanyDriveFolder)
    private readonly folders: Repository<CompanyDriveFolder>,
    @InjectRepository(CompanyDriveFile)
    private readonly files: Repository<CompanyDriveFile>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    await this.requireStaff(actor);
    const rows = await this.folders.find({
      where: { active: true },
      order: { name: 'ASC' },
      take: DRIVE_FOLDER_LIMIT,
    });
    return { folders: rows.map((row) => ({ id: row.id, name: row.name })) };
  }

  async mineFolder(actor: AuthUser, folderId: string) {
    await this.requireStaff(actor);
    const folder = await this.requireFolder(folderId);
    if (!folder.active) throw new BadRequestException('This folder is paused');
    const rows = await this.files.find({
      where: { folderId: folder.id, active: true },
      order: { name: 'ASC' },
      take: DRIVE_FILES_PER_FOLDER,
      select: this.fileCardColumns(),
    });
    return {
      folder: { id: folder.id, name: folder.name },
      files: rows.map((row) => this.toFileCard(row)),
    };
  }

  async addMine(actor: AuthUser, folderId: string, upload: DriveUpload) {
    const user = await this.requireStaff(actor);
    const folder = await this.requireFolder(folderId);
    if (!folder.active) throw new BadRequestException('This folder is paused');
    const saved = await this.insertFile(folder.id, user.id, upload);
    await this.audit(user.id, 'company_drive_file_add', 'company_drive_file', saved.id, {
      folderId: folder.id,
      name: saved.name,
      size: saved.size,
    });
    return this.toFileCard(saved);
  }

  async downloadMine(actor: AuthUser, fileId: string): Promise<StreamableFile> {
    await this.requireStaff(actor);
    const file = await this.files.findOne({ where: { id: fileId } });
    if (!file || !file.active) throw new NotFoundException('This file was not found');
    const folder = await this.folders.findOne({ where: { id: file.folderId } });
    if (!folder?.active) throw new NotFoundException('This file was not found');
    return this.stream(file);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.folders.find({ order: { name: 'ASC' }, take: DRIVE_FOLDER_LIMIT });
    const counts = await this.files
      .createQueryBuilder('file')
      .select('file.folderId', 'folderId')
      .addSelect('COUNT(*)', 'fileCount')
      .groupBy('file.folderId')
      .getRawMany<{ folderId: string; fileCount: string }>();
    const byFolder = new Map(counts.map((row) => [row.folderId, Number(row.fileCount) || 0]));
    return {
      folders: rows.map((row) => ({
        id: row.id,
        name: row.name,
        active: row.active,
        fileCount: byFolder.get(row.id) ?? 0,
      })),
    };
  }

  async adminFolder(actor: AuthUser, folderId: string) {
    await this.requireReviewer(actor);
    const folder = await this.requireFolder(folderId);
    const rows = await this.files.find({
      where: { folderId: folder.id },
      order: { name: 'ASC' },
      take: DRIVE_FILES_PER_FOLDER,
      select: this.fileCardColumns(),
    });
    const names = await this.uploaderNames(rows.map((row) => row.uploaderId));
    return {
      folder: { id: folder.id, name: folder.name, active: folder.active },
      files: rows.map((row) => ({
        ...this.toFileCard(row),
        active: row.active,
        uploaderName: names.get(row.uploaderId) ?? null,
      })),
    };
  }

  async saveFolder(actor: AuthUser, dto: SaveDriveFolderDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    if (!id) {
      const count = await this.folders.count();
      if (count >= DRIVE_FOLDER_LIMIT) {
        throw new BadRequestException('The company already has 40 folders');
      }
    }
    const row = id
      ? await this.requireFolder(id)
      : this.folders.create({ name: 'pending', nameKey: 'pending', active: true });
    try {
      const name = normalizeDriveFolderName(dto.name);
      row.name = name;
      row.nameKey = driveFolderKey(name);
      if (typeof dto.active === 'boolean') row.active = dto.active;
    } catch (error) {
      throw this.statusError(error);
    }
    let saved: CompanyDriveFolder;
    try {
      saved = await this.folders.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) throw new BadRequestException('That folder already exists');
      throw error;
    }
    await this.audit(
      user.id,
      id ? 'company_drive_folder_update' : 'company_drive_folder_create',
      'company_drive_folder',
      saved.id,
      { name: saved.name },
    );
    return { id: saved.id, name: saved.name, active: saved.active };
  }

  async addAdmin(actor: AuthUser, folderId: string, upload: DriveUpload) {
    const user = await this.requireSuperAdmin(actor);
    const folder = await this.requireFolder(folderId);
    const saved = await this.insertFile(folder.id, user.id, upload);
    await this.audit(user.id, 'company_drive_file_add', 'company_drive_file', saved.id, {
      folderId: folder.id,
      name: saved.name,
      size: saved.size,
    });
    return { ...this.toFileCard(saved), active: saved.active };
  }

  async setFileActive(actor: AuthUser, fileId: string, dto: SetDriveFileActiveDto) {
    const user = await this.requireSuperAdmin(actor);
    const row = await this.files.findOne({
      where: { id: fileId },
      select: { id: true, active: true },
    });
    if (!row) throw new NotFoundException('This file was not found');
    await this.files.update({ id: row.id }, { active: dto.active });
    await this.audit(user.id, 'company_drive_file_update', 'company_drive_file', row.id, {
      active: dto.active,
    });
    return { id: row.id, active: dto.active };
  }

  async downloadAdmin(actor: AuthUser, fileId: string): Promise<StreamableFile> {
    await this.requireReviewer(actor);
    const file = await this.files.findOne({ where: { id: fileId } });
    if (!file) throw new NotFoundException('This file was not found');
    return this.stream(file);
  }

  private async insertFile(folderId: string, uploaderId: string, upload: DriveUpload) {
    const count = await this.files.count({ where: { folderId } });
    if (count >= DRIVE_FILES_PER_FOLDER) {
      throw new BadRequestException('This folder already has 80 files');
    }
    const buffer = upload.buffer;
    let parts: ReturnType<typeof driveFileParts>;
    try {
      assertDriveBytes(buffer?.length ?? 0);
      parts = driveFileParts(upload.originalName || '');
    } catch (error) {
      throw this.statusError(error);
    }
    const row = this.files.create({
      folderId,
      name: parts.name,
      nameKey: parts.key,
      ext: parts.ext,
      mime: driveMime(parts.ext),
      size: buffer.length,
      data: buffer,
      uploaderId,
      active: true,
    });
    try {
      return await this.files.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new BadRequestException('That file is already in this folder');
      }
      throw error;
    }
  }

  private stream(file: CompanyDriveFile): StreamableFile {
    const bytes = Buffer.isBuffer(file.data) ? file.data : Buffer.from(file.data);
    return new StreamableFile(bytes, {
      type: file.mime,
      disposition: driveContentDisposition(file.name),
      length: bytes.length,
    });
  }

  private fileCardColumns() {
    return {
      id: true,
      folderId: true,
      name: true,
      nameKey: true,
      ext: true,
      mime: true,
      size: true,
      uploaderId: true,
      active: true,
      createdAt: true,
    } as const;
  }

  private toFileCard(row: Pick<CompanyDriveFile, 'id' | 'name' | 'mime' | 'size' | 'createdAt'>) {
    return {
      id: row.id,
      name: row.name,
      mime: row.mime,
      size: row.size,
      createdAt: row.createdAt,
    };
  }

  private async uploaderNames(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireFolder(id: string): Promise<CompanyDriveFolder> {
    const folder = await this.folders.findOne({ where: { id } });
    if (!folder) throw new NotFoundException('This folder was not found');
    return folder;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'DRIVE_FOLDER_NAME':
        return new BadRequestException('Enter a folder name up to 40 characters');
      case 'DRIVE_FILE_NAME':
        return new BadRequestException('Enter a file name up to 80 characters');
      case 'DRIVE_TYPE':
        return new BadRequestException('This file type is not allowed');
      case 'DRIVE_SIZE':
        return new BadRequestException('Each file must be from 1 byte to 8 MB');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the file');
    }
  }

  private async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (
      !user ||
      user.deletedAt ||
      (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
    ) {
      throw new ForbiddenException('Staff only');
    }
    return user;
  }

  private async requireReviewer(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (!canOpenInternalOps(user)) {
      throw new ForbiddenException('SuperAdmin or Internal Ops only');
    }
    return user;
  }

  private async requireSuperAdmin(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (user.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
    return user;
  }

  private async audit(
    actorId: string,
    action: string,
    resourceType: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({ actorId, action, resourceType, resourceId, meta }),
    );
  }
}

export type DriveUpload = { originalName: string; buffer: Buffer };

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
