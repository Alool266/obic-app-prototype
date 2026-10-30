// Made by Dr Ali
// Customers upload an HTML package. SuperAdmin approves, rejects, or disables.
// Public list is approved packages only. No tokens, email, phone, or partner URLs.

import { randomBytes, timingSafeEqual } from 'crypto';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { customerAlertDeskEmail } from '../notifications/customer-alert-routing';
import { User } from '../users/user.entity';
import { DeskMiniAppFlag } from './desk-mini-app-flag.entity';
import { MiniAppFile } from './mini-app-file.entity';
import { MiniApp } from './mini-app.entity';
import {
  hostedPackageIndexPath,
  PackageFile,
  unpackMiniAppZip,
} from './mini-app-package';
import {
  MiniAppReviewAction,
  MiniAppStatus,
  assertReviewTransition,
} from './mini-app-status';
import { normalizeIconUrl } from './mini-app-url';

const kMaxPerUser = 30;

/** First-party shelf ids — Desk can enable/disable without wiping partner review. */
export const kFirstPartyMiniAppIds = [
  'obic-notes',
  'obic-documents',
  'obic-spreadsheets',
  'obic-pdf',
  'obic-slides',
  'obic-china-in-hand',
  'obic-mideast-in-hand',
  'obic-africa-in-hand',
  'obic-daily',
  'obic-travel',
  'obic-yemen-in-hand',
  'obic-music',
  'obic-web',
] as const;

export type ServedPackageFile = {
  data: Buffer;
  mime: string;
  approved: boolean;
};

@Injectable()
export class MiniAppsService {
  constructor(
    @InjectRepository(MiniApp)
    private readonly apps: Repository<MiniApp>,
    @InjectRepository(MiniAppFile)
    private readonly files: Repository<MiniAppFile>,
    @InjectRepository(DeskMiniAppFlag)
    private readonly deskFlags: Repository<DeskMiniAppFlag>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly notifications: NotificationsService,
  ) {}

  /** Public map of first-party mini-app enablement for the mobile shelf. */
  async listFirstPartyFlags(): Promise<{
    rows: Array<{ appId: string; enabled: boolean }>;
  }> {
    const rows = await this.deskFlags.find();
    const byId = new Map(rows.map((r) => [r.appId, r.enabled]));
    return {
      rows: kFirstPartyMiniAppIds.map((appId) => ({
        appId,
        enabled: byId.has(appId) ? Boolean(byId.get(appId)) : appId !== 'obic-slides',
      })),
    };
  }

  async listDeskFlags(actor: AuthUser) {
    await this.requireSuperAdmin(actor);
    return this.listFirstPartyFlags();
  }

  async setDeskFlag(actor: AuthUser, appId: string, enabled: boolean) {
    await this.requireSuperAdmin(actor);
    const id = appId.trim().toLowerCase();
    if (!(kFirstPartyMiniAppIds as readonly string[]).includes(id)) {
      throw new BadRequestException('Unknown first-party mini-app');
    }
    let row = await this.deskFlags.findOne({ where: { appId: id } });
    if (!row) {
      row = this.deskFlags.create({
        appId: id,
        enabled,
        updatedBy: actor.userId,
      });
    } else {
      row.enabled = enabled;
      row.updatedBy = actor.userId;
    }
    await this.deskFlags.save(row);
    return { appId: id, enabled: row.enabled };
  }

  async submit(
    actor: AuthUser,
    input: {
      name: string;
      description: string;
      iconUrl?: string;
      zip: Buffer;
    },
  ) {
    const name = input.name.trim().slice(0, 80);
    const description = input.description.trim().slice(0, 400);
    const iconUrl = normalizeIconUrl(input.iconUrl);
    const packed = unpackMiniAppZip(input.zip);
    const pending = await this.apps.findOne({
      where: { ownerUserId: actor.userId, status: MiniAppStatus.Pending },
      order: { updatedAt: 'DESC' },
    });
    if (pending) {
      pending.name = name;
      pending.description = description;
      pending.iconUrl = iconUrl;
      pending.reviewNote = null;
      pending.supersedesId = await this.approvedTwinId(
        actor.userId,
        name,
        pending.id,
      );
      pending.startUrl = hostedPackageIndexPath(pending.id);
      await this.writePackage(pending, packed);
      await this.alertDesk(actor.userId, pending.id, pending.name);
      return this.toOwnerDto(pending);
    }

    const count = await this.apps.count({
      where: { ownerUserId: actor.userId },
    });
    if (count >= kMaxPerUser) {
      throw new BadRequestException('Too many mini app submissions');
    }
    const created = await this.apps.save(
      this.apps.create({
        ownerUserId: actor.userId,
        name,
        description,
        iconUrl,
        startUrl: '/v1/mini-apps/pending/files/index.html',
        status: MiniAppStatus.Pending,
        reviewNote: null,
        reviewerUserId: null,
        reviewedAt: null,
        supersedesId: null,
        previewTicket: null,
      }),
    );
    created.startUrl = hostedPackageIndexPath(created.id);
    created.supersedesId = await this.approvedTwinId(
      actor.userId,
      name,
      created.id,
    );
    await this.writePackage(created, packed);
    await this.alertDesk(actor.userId, created.id, created.name);
    return this.toOwnerDto(created);
  }

  private async alertDesk(customerUserId: string, id: string, name: string) {
    try {
      const email = customerAlertDeskEmail('mini_app');
      const user = await this.users.findOne({
        where: { email, role: UserRole.Employee },
      });
      if (!user || user.id === customerUserId) return;
      await this.notifications.createForUsers({
        userIds: [user.id],
        kind: NotificationKind.System,
        title: 'Mini app submitted',
        body: name.trim() || 'A customer submitted a mini app',
        data: { type: 'mini_app', miniAppId: id },
      });
    } catch {
      // The package is already saved.
    }
  }

  async listMine(actor: AuthUser) {
    const rows = await this.apps.find({
      where: { ownerUserId: actor.userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
    return rows.map((row) => this.toOwnerDto(row));
  }

  /** Approved and not disabled. Each item points at OBIC's hosted index. */
  async listPublic() {
    const rows = await this.apps.find({
      where: { status: MiniAppStatus.Approved },
      order: { name: 'ASC' },
      take: 200,
    });
    const ready = await this.idsWithIndex(rows.map((row) => row.id));
    return rows
      .filter((row) => ready.has(row.id))
      .map((row) => this.toPublicDto(row));
  }

  async listForSuperAdmin(actor: AuthUser) {
    await this.requireSuperAdmin(actor);
    const rows = await this.apps.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
    const names = await this.ownerNames(rows.map((row) => row.ownerUserId));
    return rows.map((row) => this.toAdminDto(row, names.get(row.ownerUserId) ?? null));
  }

  async getForSuperAdmin(actor: AuthUser, id: string) {
    await this.requireSuperAdmin(actor);
    const row = await this.findOrThrow(id);
    const names = await this.ownerNames([row.ownerUserId]);
    return this.toAdminDto(row, names.get(row.ownerUserId) ?? null);
  }

  /** Path the boss's browser can open. Relative links stay under the ticket. */
  async previewForSuperAdmin(actor: AuthUser, id: string) {
    await this.requireSuperAdmin(actor);
    const row = await this.findOrThrow(id);
    if (
      row.status !== MiniAppStatus.Pending &&
      row.status !== MiniAppStatus.Approved
    ) {
      throw new NotFoundException('Mini app package is not open');
    }
    if (row.status === MiniAppStatus.Approved) {
      return { previewPath: hostedPackageIndexPath(row.id) };
    }
    const ticket = randomBytes(24).toString('base64url');
    row.previewTicket = ticket;
    await this.apps.save(row);
    return {
      previewPath: `/v1/mini-apps/${row.id}/preview/${ticket}/index.html`,
    };
  }

  async review(
    actor: AuthUser,
    id: string,
    action: MiniAppReviewAction,
    reason?: string,
  ) {
    await this.requireSuperAdmin(actor);
    const row = await this.findOrThrow(id);
    const note = (reason ?? '').trim();
    if (action === 'reject' && note.length < 2) {
      throw new BadRequestException('A short rejection reason is required');
    }
    row.status = assertReviewTransition(row.status, action);
    row.reviewerUserId = actor.userId;
    row.reviewedAt = new Date();
    row.reviewNote = reviewNoteFor(action, note, row.reviewNote);
    row.previewTicket = null;
    row.startUrl = hostedPackageIndexPath(row.id);
    if (action === 'approve' && row.supersedesId) {
      await this.retireSuperseded(row.supersedesId, row.ownerUserId, actor.userId);
    }
    const saved = await this.apps.save(row);
    const names = await this.ownerNames([saved.ownerUserId]);
    return this.toAdminDto(saved, names.get(saved.ownerUserId) ?? null);
  }

  /** Approved packages only. Pending bytes use the preview path. */
  async readApprovedFile(id: string, relPath: string): Promise<ServedPackageFile> {
    const row = await this.apps.findOne({ where: { id } });
    if (!row || row.status !== MiniAppStatus.Approved) {
      throw new NotFoundException('Mini app file not found');
    }
    return this.readStoredFile(id, relPath, true);
  }

  async readPreviewFile(
    id: string,
    ticket: string,
    relPath: string,
  ): Promise<ServedPackageFile> {
    const row = await this.apps.findOne({ where: { id } });
    if (!row || row.status !== MiniAppStatus.Pending || !ticketMatches(row.previewTicket, ticket)) {
      throw new NotFoundException('Mini app file not found');
    }
    return this.readStoredFile(id, relPath, false);
  }

  private async readStoredFile(
    id: string,
    relPath: string,
    approved: boolean,
  ): Promise<ServedPackageFile> {
    const file = await this.files.findOne({
      where: { miniAppId: id, path: relPath },
    });
    if (!file) throw new NotFoundException('Mini app file not found');
    return { data: file.data, mime: file.mime, approved };
  }

  private async writePackage(row: MiniApp, packed: PackageFile[]) {
    const records = packed.map((file) =>
      this.files.create({
        miniAppId: row.id,
        path: file.path,
        mime: file.mime,
        size: file.data.length,
        data: file.data,
      }),
    );
    await this.apps.manager.transaction(async (em) => {
      await em.delete(MiniAppFile, { miniAppId: row.id });
      await em.save(MiniAppFile, records);
      await em.save(MiniApp, row);
    });
  }

  private async approvedTwinId(ownerUserId: string, name: string, exceptId: string) {
    const rows = await this.apps.find({
      where: { ownerUserId, status: MiniAppStatus.Approved },
      order: { updatedAt: 'DESC' },
      take: 30,
    });
    const twin = rows.find(
      (row) => row.id !== exceptId && row.name.toLowerCase() === name.toLowerCase(),
    );
    return twin?.id ?? null;
  }

  private async retireSuperseded(
    previousId: string,
    ownerUserId: string,
    reviewerId: string,
  ) {
    const previous = await this.apps.findOne({ where: { id: previousId } });
    if (
      !previous ||
      previous.ownerUserId !== ownerUserId ||
      previous.status !== MiniAppStatus.Approved
    ) {
      return;
    }
    previous.status = MiniAppStatus.Disabled;
    previous.previewTicket = null;
    previous.reviewerUserId = reviewerId;
    previous.reviewedAt = new Date();
    await this.apps.save(previous);
  }

  private async idsWithIndex(ids: string[]) {
    if (!ids.length) return new Set<string>();
    const rows = await this.files.find({
      where: { miniAppId: In(ids), path: 'index.html' },
      select: ['miniAppId', 'path'],
    });
    return new Set(rows.map((row) => row.miniAppId));
  }

  private async findOrThrow(id: string) {
    const row = await this.apps.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Mini app not found');
    return row;
  }

  private async requireSuperAdmin(actor: AuthUser) {
    const row = await this.users.findOne({
      where: { id: actor.userId },
      select: ['id', 'role'],
    });
    if (!row || row.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
  }

  private async ownerNames(ids: string[]) {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map<string, string>();
    const users = await this.users.find({
      where: { id: In(unique) },
      select: ['id', 'name'],
    });
    return new Map(users.map((user) => [user.id, user.name]));
  }

  private toPublicDto(row: MiniApp) {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      iconUrl: row.iconUrl,
      startUrl: hostedPackageIndexPath(row.id),
      status: MiniAppStatus.Approved,
    };
  }

  private toOwnerDto(row: MiniApp) {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      iconUrl: row.iconUrl,
      startUrl: hostedPackageIndexPath(row.id),
      status: row.status,
      reviewNote: row.reviewNote,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      reviewedAt: row.reviewedAt,
    };
  }

  private toAdminDto(row: MiniApp, ownerName: string | null) {
    return {
      ...this.toOwnerDto(row),
      ownerUserId: row.ownerUserId,
      ownerName,
      reviewerUserId: row.reviewerUserId,
    };
  }
}

function reviewNoteFor(
  action: MiniAppReviewAction,
  note: string,
  current: string | null,
): string | null {
  switch (action) {
    case 'approve':
      return null;
    case 'reject':
      return note.slice(0, 500);
    case 'disable':
      return current;
    default: {
      const _exhaustive: never = action;
      return _exhaustive;
    }
  }
}

function ticketMatches(stored: string | null, given: string): boolean {
  if (!stored || !given) return false;
  const a = Buffer.from(stored);
  const b = Buffer.from(given);
  if (a.length !== b.length || a.length === 0) return false;
  return timingSafeEqual(a, b);
}
