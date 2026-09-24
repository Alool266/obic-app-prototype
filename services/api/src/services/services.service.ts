// Made by Dr Ali
// Public catalog reads + SuperAdmin catalog CRUD. Redis caches active list.

import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RedisService } from '../redis/redis.service';
import {
  AdminCreateServiceDto,
  AdminUpdateServiceDto,
} from './dto/admin-service.dto';
import {
  AdminCreateSubServiceDto,
  AdminUpdateSubServiceDto,
} from './dto/admin-sub-service.dto';
import { isAvailableInCountry, normalizeCountryCode, parseCountriesInput } from './country-availability';
import { Service } from './service.entity';
import { ServiceSub } from './service-sub.entity';

const SERVICES_LIST_CACHE_KEY = 'obic:v1:services:active';
const SERVICES_LIST_TTL_SEC = 60;
const servicesListCacheKey = (country?: string) => {
  const c = normalizeCountryCode(country);
  return c ? `${SERVICES_LIST_CACHE_KEY}:${c}` : SERVICES_LIST_CACHE_KEY;
};
const subServicesCacheKey = (parentSlug: string, country?: string) => {
  const c = normalizeCountryCode(country);
  const base = `obic:v1:services:${parentSlug}:subs`;
  return c ? `${base}:${c}` : base;
};

export type ServiceDto = {
  id: string;
  slug: string;
  icon: string;
  colorKey: string | null;
  sortOrder: number;
  nameAr: string;
  nameEn: string;
  nameZh: string;
  descAr: string;
  descEn: string;
  descZh: string;
  priceAr: string;
  priceEn: string;
  priceZh: string;
  availableInRegion?: boolean;
};

export type AdminServiceDto = ServiceDto & {
  isActive: boolean;
  countries: string[];
  createdAt: string;
  updatedAt: string;
};

export type SubServiceDto = {
  id: string;
  parentSlug: string;
  icon: string;
  sortOrder: number;
  nameAr: string;
  nameEn: string;
  nameZh: string;
  descAr: string;
  descEn: string;
  descZh: string;
  priceAr: string;
  priceEn: string;
  priceZh: string;
  availableInRegion?: boolean;
};

export type AdminSubServiceDto = SubServiceDto & {
  uuid: string;
  serviceId: string;
  isActive: boolean;
  countries: string[];
  createdAt: string;
  updatedAt: string;
};

@Injectable()
export class ServicesService {
  constructor(
    @InjectRepository(Service)
    private readonly servicesRepo: Repository<Service>,
    @InjectRepository(ServiceSub)
    private readonly subsRepo: Repository<ServiceSub>,
    private readonly redis: RedisService,
  ) {}

  async listActive(
    country?: string | null,
    includeUnavailable = false,
  ): Promise<ServiceDto[]> {
    const cacheKey = servicesListCacheKey(country ?? undefined);
    const cached = await this.redis.getJson<ServiceDto[]>(cacheKey);
    if (cached) return cached;

    const rows = await this.servicesRepo.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC' },
    });
    const normalizedCountry = normalizeCountryCode(country);
    const dtos = rows
      .map((s) => this.toDto(s, normalizedCountry))
      .filter(
        (dto) =>
          includeUnavailable ||
          !normalizedCountry ||
          dto.availableInRegion !== false,
      );
    await this.redis.setJson(cacheKey, dtos, SERVICES_LIST_TTL_SEC);
    return dtos;
  }

  async listAllAdmin(): Promise<AdminServiceDto[]> {
    const rows = await this.servicesRepo.find({
      order: { sortOrder: 'ASC' },
    });
    return rows.map((s) => this.toAdminDto(s));
  }

  async findByIdOrSlug(idOrSlug: string): Promise<ServiceDto> {
    const bySlug = await this.servicesRepo.findOne({
      where: { slug: idOrSlug, isActive: true },
    });
    if (bySlug) return this.toDto(bySlug, undefined);

    const uuidLike =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        idOrSlug,
      );
    if (uuidLike) {
      const byId = await this.servicesRepo.findOne({
        where: { id: idOrSlug, isActive: true },
      });
      if (byId) return this.toDto(byId, undefined);
    }

    throw new NotFoundException('Service not found');
  }

  async findByIdOrSlugForRegion(
    idOrSlug: string,
    country?: string | null,
  ): Promise<ServiceDto> {
    const dto = await this.findByIdOrSlug(idOrSlug);
    const normalizedCountry = normalizeCountryCode(country);
    if (
      normalizedCountry &&
      !isAvailableInCountry(
        await this.countriesForServiceId(dto.id),
        normalizedCountry,
      )
    ) {
      return { ...dto, availableInRegion: false };
    }
    return { ...dto, availableInRegion: true };
  }

  private async countriesForServiceId(serviceId: string): Promise<string[]> {
    const row = await this.servicesRepo.findOne({ where: { id: serviceId } });
    return row?.countries ?? [];
  }

  async requireActiveId(serviceId: string): Promise<Service> {
    const row = await this.servicesRepo.findOne({
      where: { id: serviceId, isActive: true },
    });
    if (!row) {
      throw new NotFoundException('Service not found');
    }
    return row;
  }

  async createAdmin(dto: AdminCreateServiceDto): Promise<AdminServiceDto> {
    const slug = dto.slug.trim().toLowerCase();
    const existing = await this.servicesRepo.findOne({ where: { slug } });
    if (existing) {
      throw new ConflictException('Service slug already exists');
    }
    const row = this.servicesRepo.create({
      slug,
      icon: dto.icon,
      colorKey: dto.colorKey ?? null,
      sortOrder: dto.sortOrder ?? 0,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      nameZh: dto.nameZh ?? '',
      descAr: dto.descAr,
      descEn: dto.descEn,
      descZh: dto.descZh ?? '',
      priceAr: dto.priceAr,
      priceEn: dto.priceEn,
      priceZh: dto.priceZh ?? '',
      isActive: dto.isActive ?? true,
      countries: parseCountriesInput(dto.countries),
    });
    const saved = await this.servicesRepo.save(row);
    await this.bustCache();
    return this.toAdminDto(saved);
  }

  async updateAdmin(
    id: string,
    dto: AdminUpdateServiceDto,
  ): Promise<AdminServiceDto> {
    const row = await this.servicesRepo.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Service not found');

    if (dto.slug !== undefined) {
      const slug = dto.slug.trim().toLowerCase();
      const clash = await this.servicesRepo.findOne({ where: { slug } });
      if (clash && clash.id !== id) {
        throw new ConflictException('Service slug already exists');
      }
      row.slug = slug;
    }
    if (dto.icon !== undefined) row.icon = dto.icon;
    if (dto.colorKey !== undefined) row.colorKey = dto.colorKey;
    if (dto.sortOrder !== undefined) row.sortOrder = dto.sortOrder;
    if (dto.nameAr !== undefined) row.nameAr = dto.nameAr;
    if (dto.nameEn !== undefined) row.nameEn = dto.nameEn;
    if (dto.nameZh !== undefined) row.nameZh = dto.nameZh;
    if (dto.descAr !== undefined) row.descAr = dto.descAr;
    if (dto.descEn !== undefined) row.descEn = dto.descEn;
    if (dto.descZh !== undefined) row.descZh = dto.descZh;
    if (dto.priceAr !== undefined) row.priceAr = dto.priceAr;
    if (dto.priceEn !== undefined) row.priceEn = dto.priceEn;
    if (dto.priceZh !== undefined) row.priceZh = dto.priceZh;
    if (dto.isActive !== undefined) row.isActive = dto.isActive;
    if (dto.countries !== undefined) {
      row.countries = parseCountriesInput(dto.countries);
    }

    const saved = await this.servicesRepo.save(row);
    await this.bustCache();
    return this.toAdminDto(saved);
  }

  async listSubServicesByParentSlug(
    parentSlug: string,
    country?: string | null,
    includeUnavailable = false,
  ): Promise<SubServiceDto[]> {
    const cacheKey = subServicesCacheKey(parentSlug, country ?? undefined);
    const cached = await this.redis.getJson<SubServiceDto[]>(cacheKey);
    if (cached) return cached;

    const parent = await this.servicesRepo.findOne({
      where: { slug: parentSlug, isActive: true },
    });
    if (!parent) throw new NotFoundException('Service not found');

    const rows = await this.subsRepo.find({
      where: { serviceId: parent.id, isActive: true },
      order: { sortOrder: 'ASC' },
    });
    const normalizedCountry = normalizeCountryCode(country);
    const dtos = rows
      .map((r) => this.toSubDto(r, parent.slug, normalizedCountry))
      .filter(
        (dto) =>
          includeUnavailable ||
          !normalizedCountry ||
          dto.availableInRegion !== false,
      );
    await this.redis.setJson(cacheKey, dtos, SERVICES_LIST_TTL_SEC);
    return dtos;
  }

  async listSubServicesAdmin(serviceId: string): Promise<AdminSubServiceDto[]> {
    const parent = await this.servicesRepo.findOne({ where: { id: serviceId } });
    if (!parent) throw new NotFoundException('Service not found');
    const rows = await this.subsRepo.find({
      where: { serviceId },
      order: { sortOrder: 'ASC' },
    });
    return rows.map((r) => this.toAdminSubDto(r, parent.slug));
  }

  async createSubServiceAdmin(
    dto: AdminCreateSubServiceDto,
  ): Promise<AdminSubServiceDto> {
    const parent = await this.servicesRepo.findOne({ where: { id: dto.serviceId } });
    if (!parent) throw new NotFoundException('Service not found');
    const externalId = dto.externalId.trim();
    const clash = await this.subsRepo.findOne({
      where: { serviceId: dto.serviceId, externalId },
    });
    if (clash) throw new ConflictException('Sub-service id already exists');

    const row = this.subsRepo.create({
      serviceId: dto.serviceId,
      externalId,
      icon: dto.icon,
      sortOrder: dto.sortOrder ?? 0,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      nameZh: dto.nameZh ?? '',
      descAr: dto.descAr ?? '',
      descEn: dto.descEn ?? '',
      descZh: dto.descZh ?? '',
      priceAr: dto.priceAr ?? '',
      priceEn: dto.priceEn ?? '',
      priceZh: dto.priceZh ?? '',
      isActive: dto.isActive ?? true,
      countries: parseCountriesInput(dto.countries),
    });
    const saved = await this.subsRepo.save(row);
    await this.bustSubCache(parent.slug);
    return this.toAdminSubDto(saved, parent.slug);
  }

  async updateSubServiceAdmin(
    id: string,
    dto: AdminUpdateSubServiceDto,
  ): Promise<AdminSubServiceDto> {
    const row = await this.subsRepo.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Sub-service not found');
    const parent = await this.servicesRepo.findOne({ where: { id: row.serviceId } });
    if (!parent) throw new NotFoundException('Service not found');

    if (dto.externalId !== undefined) {
      const externalId = dto.externalId.trim();
      const clash = await this.subsRepo.findOne({
        where: { serviceId: row.serviceId, externalId },
      });
      if (clash && clash.id !== id) {
        throw new ConflictException('Sub-service id already exists');
      }
      row.externalId = externalId;
    }
    if (dto.icon !== undefined) row.icon = dto.icon;
    if (dto.sortOrder !== undefined) row.sortOrder = dto.sortOrder;
    if (dto.nameAr !== undefined) row.nameAr = dto.nameAr;
    if (dto.nameEn !== undefined) row.nameEn = dto.nameEn;
    if (dto.nameZh !== undefined) row.nameZh = dto.nameZh;
    if (dto.descAr !== undefined) row.descAr = dto.descAr;
    if (dto.descEn !== undefined) row.descEn = dto.descEn;
    if (dto.descZh !== undefined) row.descZh = dto.descZh;
    if (dto.priceAr !== undefined) row.priceAr = dto.priceAr;
    if (dto.priceEn !== undefined) row.priceEn = dto.priceEn;
    if (dto.priceZh !== undefined) row.priceZh = dto.priceZh;
    if (dto.isActive !== undefined) row.isActive = dto.isActive;
    if (dto.countries !== undefined) {
      row.countries = parseCountriesInput(dto.countries);
    }

    const saved = await this.subsRepo.save(row);
    await this.bustSubCache(parent.slug);
    return this.toAdminSubDto(saved, parent.slug);
  }

  private async bustCache(): Promise<void> {
    await this.redis.del(SERVICES_LIST_CACHE_KEY);
    await this.redis.delByPattern(`${SERVICES_LIST_CACHE_KEY}:*`);
  }

  private async bustSubCache(parentSlug: string): Promise<void> {
    await this.redis.del(subServicesCacheKey(parentSlug));
    await this.redis.delByPattern(`${subServicesCacheKey(parentSlug)}:*`);
  }

  private toDto(s: Service, country?: string): ServiceDto {
    const available =
      country === undefined
        ? undefined
        : isAvailableInCountry(s.countries, country);
    return {
      id: s.id,
      slug: s.slug,
      icon: s.icon,
      colorKey: s.colorKey,
      sortOrder: s.sortOrder,
      nameAr: s.nameAr,
      nameEn: s.nameEn,
      nameZh: s.nameZh,
      descAr: s.descAr,
      descEn: s.descEn,
      descZh: s.descZh,
      priceAr: s.priceAr,
      priceEn: s.priceEn,
      priceZh: s.priceZh,
      ...(available === undefined ? {} : { availableInRegion: available }),
    };
  }

  private toAdminDto(s: Service): AdminServiceDto {
    return {
      ...this.toDto(s),
      isActive: s.isActive,
      countries: s.countries ?? [],
      createdAt: s.createdAt.toISOString(),
      updatedAt: s.updatedAt.toISOString(),
    };
  }

  private toSubDto(
    row: ServiceSub,
    parentSlug: string,
    country?: string,
  ): SubServiceDto {
    const available =
      country === undefined
        ? undefined
        : isAvailableInCountry(row.countries, country);
    return {
      id: row.externalId,
      parentSlug,
      icon: row.icon,
      sortOrder: row.sortOrder,
      nameAr: row.nameAr,
      nameEn: row.nameEn,
      nameZh: row.nameZh,
      descAr: row.descAr,
      descEn: row.descEn,
      descZh: row.descZh,
      priceAr: row.priceAr,
      priceEn: row.priceEn,
      priceZh: row.priceZh,
      ...(available === undefined ? {} : { availableInRegion: available }),
    };
  }

  private toAdminSubDto(row: ServiceSub, parentSlug: string): AdminSubServiceDto {
    return {
      ...this.toSubDto(row, parentSlug),
      uuid: row.id,
      serviceId: row.serviceId,
      isActive: row.isActive,
      countries: row.countries ?? [],
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}
