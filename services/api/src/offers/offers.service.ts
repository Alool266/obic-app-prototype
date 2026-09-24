// Made by Dr Ali
// Offers service — public available list; staff CRUD with ownership (SuperAdmin: all).

import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User } from '../users/user.entity';
import { canManageOffers } from '../users/user.mapper';
import {
  CreateOfferDto,
  OfferListQueryDto,
  UpdateOfferDto,
} from './dto/offer.dto';
import { Offer } from './offer.entity';

export type OfferListFilters = {
  kind?: string;
  q?: string;
  city?: string;
};

/** Resolve kind/type query to a slug, or undefined (no filter). */
export function resolveOfferKindFilter(
  kind?: string,
  type?: string,
): string | undefined {
  const raw = (kind || type || '').trim().toLowerCase();
  if (!raw) return undefined;
  if (!/^[a-z][a-z0-9_-]{1,31}$/.test(raw)) return undefined;
  return raw;
}

export function filtersFromQuery(query?: OfferListQueryDto): OfferListFilters {
  return {
    kind: resolveOfferKindFilter(query?.kind, query?.type),
    q: query?.q?.trim() || undefined,
    city: query?.city?.trim() || undefined,
  };
}

@Injectable()
export class OffersService {
  constructor(
    @InjectRepository(Offer) private readonly offers: Repository<Offer>,
    @InjectRepository(User) private readonly users: Repository<User>,
  ) {}

  /** Load staff row and require canManageOffers (SuperAdmin or offersAccess). */
  private async requireOffersManager(actor: AuthUser): Promise<User> {
    const u = await this.users.findOne({ where: { id: actor.userId } });
    if (!u || !canManageOffers(u)) {
      throw new ForbiddenException('Offers management not allowed');
    }
    return u;
  }

  /** Customer-visible: published, not sold out, not past expiry. */
  isCustomerAvailable(o: Offer, now = new Date()): boolean {
    if (!o.isPublished || o.isSoldOut) return false;
    if (o.expiresAt && o.expiresAt.getTime() <= now.getTime()) return false;
    return true;
  }

  private serialize(o: Offer, includePrivate = false) {
    const now = new Date();
    const expired = !!(o.expiresAt && o.expiresAt.getTime() <= now.getTime());
    return {
      id: o.id,
      kind: o.kind,
      titleAr: o.titleAr,
      titleEn: o.titleEn,
      bodyAr: o.bodyAr,
      bodyEn: o.bodyEn,
      priceLabelAr: o.priceLabelAr,
      priceLabelEn: o.priceLabelEn,
      locationLabel: o.locationLabel,
      datesLabel: o.datesLabel,
      media: o.media ?? [],
      attributes: o.attributes ?? {},
      isPublished: o.isPublished,
      isSoldOut: o.isSoldOut,
      expiresAt: o.expiresAt,
      isExpired: expired,
      isAvailable: this.isCustomerAvailable(o, now),
      createdById: o.createdById,
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
      ...(includePrivate
        ? {
            createdByName: o.createdBy?.name ?? null,
          }
        : {}),
    };
  }

  private parseExpiresAt(raw?: string | null): Date | null | undefined {
    if (raw === undefined) return undefined;
    if (raw === null || raw === '') return null;
    return new Date(raw);
  }

  applyListFilters(
    qb: ReturnType<Repository<Offer>['createQueryBuilder']>,
    filters?: OfferListFilters,
  ) {
    if (filters?.kind) {
      qb.andWhere('o.kind = :kind', { kind: filters.kind });
    }
    if (filters?.q) {
      qb.andWhere(
        `(o.titleAr ILIKE :q OR o.titleEn ILIKE :q OR o.bodyAr ILIKE :q OR o.bodyEn ILIKE :q OR COALESCE(o.locationLabel, '') ILIKE :q)`,
        { q: `%${filters.q}%` },
      );
    }
    if (filters?.city) {
      qb.andWhere(
        `(COALESCE(o.locationLabel, '') ILIKE :city OR o.attributes::text ILIKE :city)`,
        { city: `%${filters.city}%` },
      );
    }
    return qb;
  }

  /** Customer browse — published + not sold out + not expired. */
  async listPublished(filters?: OfferListFilters) {
    const qb = this.offers
      .createQueryBuilder('o')
      .where('o.isPublished = true')
      .andWhere('o.isSoldOut = false')
      .andWhere('(o.expiresAt IS NULL OR o.expiresAt > NOW())')
      .orderBy('o.updatedAt', 'DESC')
      .take(100);
    this.applyListFilters(qb, filters);
    const rows = await qb.getMany();
    return { items: rows.map((o) => this.serialize(o)) };
  }

  async getPublished(id: string) {
    const o = await this.offers.findOne({ where: { id } });
    if (!o || !this.isCustomerAvailable(o)) {
      throw new NotFoundException('Offer not found');
    }
    return this.serialize(o);
  }

  /**
   * Resolve an offer for order create — must be customer-available.
   * Exported for OrdersService (avoids circular module imports via method call).
   */
  async requireAvailableForOrder(id: string): Promise<Offer> {
    const o = await this.offers.findOne({ where: { id } });
    if (!o || !this.isCustomerAvailable(o)) {
      throw new NotFoundException('Offer not available');
    }
    return o;
  }

  /** Staff desk — own offers; SuperAdmin sees all. Requires canManageOffers. */
  async listForStaff(actor: AuthUser, filters?: OfferListFilters) {
    const staff = await this.requireOffersManager(actor);
    const qb = this.offers
      .createQueryBuilder('o')
      .leftJoinAndSelect('o.createdBy', 'createdBy')
      .orderBy('o.updatedAt', 'DESC')
      .take(200);
    if (staff.role !== UserRole.SuperAdmin) {
      qb.andWhere('o.createdById = :uid', { uid: actor.userId });
    }
    this.applyListFilters(qb, filters);
    const rows = await qb.getMany();
    return { items: rows.map((o) => this.serialize(o, true)) };
  }

  async create(actor: AuthUser, dto: CreateOfferDto) {
    await this.requireOffersManager(actor);
    const expiresAt = this.parseExpiresAt(dto.expiresAt);
    const row = this.offers.create({
      kind: dto.kind,
      titleAr: dto.titleAr.trim(),
      titleEn: dto.titleEn.trim(),
      bodyAr: (dto.bodyAr ?? '').trim(),
      bodyEn: (dto.bodyEn ?? '').trim(),
      priceLabelAr: dto.priceLabelAr?.trim() || null,
      priceLabelEn: dto.priceLabelEn?.trim() || null,
      locationLabel: dto.locationLabel?.trim() || null,
      datesLabel: dto.datesLabel?.trim() || null,
      media: dto.media ?? [],
      attributes: dto.attributes ?? {},
      isPublished: dto.isPublished ?? false,
      isSoldOut: dto.isSoldOut ?? false,
      expiresAt: expiresAt === undefined ? null : expiresAt,
      createdById: actor.userId,
    });
    const saved = await this.offers.save(row);
    return this.serialize(saved, true);
  }

  async update(actor: AuthUser, id: string, dto: UpdateOfferDto) {
    const staff = await this.requireOffersManager(actor);
    const o = await this.offers.findOne({
      where: { id },
      relations: ['createdBy'],
    });
    if (!o) throw new NotFoundException('Offer not found');
    if (staff.role !== UserRole.SuperAdmin && o.createdById !== actor.userId) {
      throw new ForbiddenException('Not your offer');
    }
    if (dto.kind !== undefined) o.kind = dto.kind;
    if (dto.titleAr !== undefined) o.titleAr = dto.titleAr.trim();
    if (dto.titleEn !== undefined) o.titleEn = dto.titleEn.trim();
    if (dto.bodyAr !== undefined) o.bodyAr = dto.bodyAr.trim();
    if (dto.bodyEn !== undefined) o.bodyEn = dto.bodyEn.trim();
    if (dto.priceLabelAr !== undefined) {
      o.priceLabelAr = dto.priceLabelAr?.trim() || null;
    }
    if (dto.priceLabelEn !== undefined) {
      o.priceLabelEn = dto.priceLabelEn?.trim() || null;
    }
    if (dto.locationLabel !== undefined) {
      o.locationLabel = dto.locationLabel?.trim() || null;
    }
    if (dto.datesLabel !== undefined) {
      o.datesLabel = dto.datesLabel?.trim() || null;
    }
    if (dto.media !== undefined) o.media = dto.media;
    if (dto.attributes !== undefined) o.attributes = dto.attributes;
    if (dto.isPublished !== undefined) o.isPublished = dto.isPublished;
    if (dto.isSoldOut !== undefined) o.isSoldOut = dto.isSoldOut;
    const expiresAt = this.parseExpiresAt(dto.expiresAt);
    if (expiresAt !== undefined) o.expiresAt = expiresAt;
    const saved = await this.offers.save(o);
    return this.serialize(saved, true);
  }

  async remove(actor: AuthUser, id: string) {
    const staff = await this.requireOffersManager(actor);
    const o = await this.offers.findOne({ where: { id } });
    if (!o) throw new NotFoundException('Offer not found');
    if (staff.role !== UserRole.SuperAdmin && o.createdById !== actor.userId) {
      throw new ForbiddenException('Not your offer');
    }
    await this.offers.remove(o);
    return { ok: true };
  }
}
