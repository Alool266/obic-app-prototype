// Made by Dr Ali
// Personal productivity files — create / open / save / share with friends.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Friendship } from '../friends/friendship.entity';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  CreateUserOfficeDto,
  ShareUserOfficeDto,
  UpdateUserOfficeDto,
} from './dto/user-office.dto';
import { UserOfficeItem, UserOfficeKind } from './user-office-item.entity';

const EMPTY_GRID: string[][] = Array.from({ length: 12 }, () =>
  Array.from({ length: 6 }, () => ''),
);

@Injectable()
export class UserOfficeService {
  constructor(
    @InjectRepository(UserOfficeItem)
    private readonly items: Repository<UserOfficeItem>,
    @InjectRepository(Friendship)
    private readonly friendships: Repository<Friendship>,
  ) {}

  async list(actor: AuthUser, kind?: string) {
    const k = this.normalizeKind(kind, false);
    const qb = this.items
      .createQueryBuilder('i')
      .where(
        '(i.user_id = :uid OR i.share_user_ids @> :share::jsonb)',
        { uid: actor.userId, share: JSON.stringify([actor.userId]) },
      )
      .orderBy('i.updated_at', 'DESC')
      .take(100);
    if (k) qb.andWhere('i.kind = :kind', { kind: k });
    const rows = await qb.getMany();
    return { rows: rows.map((r) => this.toCard(r, actor.userId)) };
  }

  async one(actor: AuthUser, id: string) {
    const row = await this.requireAccess(actor, id);
    return this.toCard(row, actor.userId, true);
  }

  async create(actor: AuthUser, dto: CreateUserOfficeDto) {
    const kind = this.normalizeKind(dto.kind, true)!;
    const title = (dto.title ?? '').trim().slice(0, 120) || this.defaultTitle(kind);
    if (kind === 'pdf') {
      const url = (dto.fileUrl ?? '').trim();
      if (!url || !/^https:\/\//i.test(url)) {
        throw new BadRequestException('PDF needs an https fileUrl');
      }
    }
    const row = this.items.create({
      userId: actor.userId,
      kind,
      title,
      body: kind === 'spreadsheet' || kind === 'pdf' ? '' : (dto.body ?? ''),
      grid: kind === 'spreadsheet' ? this.normalizeGrid(dto.grid) : [],
      fileUrl: kind === 'pdf' ? (dto.fileUrl ?? '').trim().slice(0, 500) : null,
      shareUserIds: [],
    });
    await this.items.save(row);
    return this.toCard(row, actor.userId, true);
  }

  async update(actor: AuthUser, id: string, dto: UpdateUserOfficeDto) {
    const row = await this.requireOwner(actor, id);
    if (dto.title != null) row.title = dto.title.trim().slice(0, 120);
    if (dto.body != null && (row.kind === 'note' || row.kind === 'document')) {
      row.body = dto.body.slice(0, 200_000);
    }
    if (dto.grid != null && row.kind === 'spreadsheet') {
      row.grid = this.normalizeGrid(dto.grid);
    }
    if (dto.fileUrl != null && row.kind === 'pdf') {
      const url = dto.fileUrl.trim();
      if (!/^https:\/\//i.test(url)) {
        throw new BadRequestException('PDF needs an https fileUrl');
      }
      row.fileUrl = url.slice(0, 500);
    }
    await this.items.save(row);
    return this.toCard(row, actor.userId, true);
  }

  async share(actor: AuthUser, id: string, dto: ShareUserOfficeDto) {
    const row = await this.requireOwner(actor, id);
    const ids = [...new Set(dto.shareUserIds.filter((x) => x !== actor.userId))];
    if (ids.length) {
      const friends = await this.friendships
        .createQueryBuilder('f')
        .where('f.user_low_id = :uid OR f.user_high_id = :uid', {
          uid: actor.userId,
        })
        .getMany();
      const allowed = new Set<string>();
      for (const f of friends) {
        allowed.add(
          f.userLowId === actor.userId ? f.userHighId : f.userLowId,
        );
      }
      for (const friendId of ids) {
        if (!allowed.has(friendId)) {
          throw new ForbiddenException('Share only with Obic contacts');
        }
      }
    }
    row.shareUserIds = ids.slice(0, 40);
    await this.items.save(row);
    return this.toCard(row, actor.userId, true);
  }

  async remove(actor: AuthUser, id: string) {
    const row = await this.requireOwner(actor, id);
    await this.items.remove(row);
    return { ok: true };
  }

  private async requireOwner(actor: AuthUser, id: string) {
    const row = await this.items.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Item not found');
    if (row.userId !== actor.userId) {
      throw new ForbiddenException('Only the owner can edit');
    }
    return row;
  }

  private async requireAccess(actor: AuthUser, id: string) {
    const row = await this.items.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Item not found');
    if (row.userId === actor.userId) return row;
    if (row.shareUserIds?.includes(actor.userId)) return row;
    throw new ForbiddenException('Not shared with you');
  }

  private normalizeKind(
    raw: string | undefined,
    required: boolean,
  ): UserOfficeKind | undefined {
    if (raw == null || raw === '') {
      if (required) throw new BadRequestException('kind required');
      return undefined;
    }
    const k = raw.trim().toLowerCase();
    if (
      k !== 'note' &&
      k !== 'document' &&
      k !== 'spreadsheet' &&
      k !== 'pdf'
    ) {
      throw new BadRequestException('Invalid kind');
    }
    return k;
  }

  private normalizeGrid(raw: unknown): string[][] {
    if (!Array.isArray(raw) || raw.length === 0) {
      return EMPTY_GRID.map((r) => [...r]);
    }
    const rows: string[][] = [];
    for (let r = 0; r < 40 && r < Math.max(raw.length, 12); r++) {
      const src = Array.isArray(raw[r]) ? (raw[r] as unknown[]) : [];
      const row: string[] = [];
      for (let c = 0; c < 12; c++) {
        const cell = src[c];
        row.push(
          typeof cell === 'string' ? cell.slice(0, 2000) : cell == null ? '' : String(cell).slice(0, 2000),
        );
      }
      rows.push(row);
    }
    while (rows.length < 12) rows.push(Array.from({ length: 12 }, () => ''));
    return rows;
  }

  private defaultTitle(kind: UserOfficeKind): string {
    switch (kind) {
      case 'note':
        return 'Note';
      case 'document':
        return 'Document';
      case 'spreadsheet':
        return 'Spreadsheet';
      case 'pdf':
        return 'PDF';
      default: {
        const _exhaustive: never = kind;
        return _exhaustive;
      }
    }
  }

  private toCard(row: UserOfficeItem, viewerId: string, full = false) {
    return {
      id: row.id,
      kind: row.kind,
      title: row.title,
      owner: row.userId === viewerId,
      shared: row.userId !== viewerId,
      shareUserIds: row.userId === viewerId ? row.shareUserIds : undefined,
      fileUrl: row.kind === 'pdf' ? row.fileUrl : undefined,
      body: full && (row.kind === 'note' || row.kind === 'document') ? row.body : undefined,
      grid: full && row.kind === 'spreadsheet' ? row.grid : undefined,
      updatedAt: row.updatedAt,
      createdAt: row.createdAt,
    };
  }
}
