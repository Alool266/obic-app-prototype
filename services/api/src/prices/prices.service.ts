// Made by Dr Ali
// Versioned prices. Only Active + in-date rows may be quoted to customers.

import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreatePriceVersionDto, TransitionPriceDto } from './dto/price.dto';
import { PriceVersion } from './price-version.entity';
import {
  assertActivatable,
  assertPriceTransition,
  computeQuoteTotals,
  type PriceStatus,
} from './price';

@Injectable()
export class PricesService {
  constructor(
    @InjectRepository(PriceVersion)
    private readonly prices: Repository<PriceVersion>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async adminList() {
    const rows = await this.prices.find({
      order: { priceId: 'ASC', version: 'ASC' },
      take: 500,
    });
    return { rows: rows.map((row) => this.toDto(row)) };
  }

  async create(actor: AuthUser, dto: CreatePriceVersionDto) {
    const exists = await this.prices.findOne({
      where: { priceId: dto.priceId, version: dto.version },
    });
    if (exists) {
      throw new ConflictException('This PriceID and version already exist');
    }
    if (dto.effectiveTo && dto.effectiveFrom && dto.effectiveTo < dto.effectiveFrom) {
      throw new BadRequestException('Effective end is before its start');
    }
    const row = await this.prices.save(
      this.prices.create({
        priceId: dto.priceId,
        version: dto.version,
        serviceKey: dto.serviceKey,
        itemName: dto.itemName.trim(),
        city: dto.city?.trim() ? dto.city.trim() : null,
        nationality: dto.nationality?.trim() ? dto.nationality.trim() : null,
        obicFeeCents: dto.obicFeeCents,
        externalFeeCents: dto.externalFeeCents ?? 0,
        currency: dto.currency ?? 'CNY',
        pricingBasis: dto.pricingBasis ?? 'per_order',
        status: 'Draft',
        effectiveFrom: dto.effectiveFrom ?? null,
        effectiveTo: dto.effectiveTo ?? null,
        approvedBy: null,
        sourceRef: dto.sourceRef?.trim() ? dto.sourceRef.trim() : null,
        note: dto.note?.trim() ? dto.note.trim() : null,
        createdBy: actor.userId,
      }),
    );
    await this.audit(actor.userId, 'price_create', row.id, {
      priceId: row.priceId,
      version: row.version,
    });
    return this.toDto(row);
  }

  async transition(actor: AuthUser, id: string, dto: TransitionPriceDto) {
    const row = await this.prices.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This price was not found');
    try {
      assertPriceTransition(row.status, dto.status);
    } catch {
      throw new BadRequestException(
        `Cannot move a price from ${row.status} to ${dto.status}`,
      );
    }
    const from: PriceStatus = row.status;
    if (dto.effectiveFrom) row.effectiveFrom = dto.effectiveFrom;
    if (dto.note?.trim()) row.note = dto.note.trim();
    if (dto.status === 'Approved') row.approvedBy = actor.userId;
    if (dto.status === 'Active') {
      try {
        assertActivatable({
          effectiveFrom: row.effectiveFrom,
          approverId: row.approvedBy,
        });
      } catch {
        throw new BadRequestException(
          'A price needs an effective date and an approver before it goes active',
        );
      }
      // One active version per PriceID: retire the previous one.
      const others = await this.prices.find({
        where: { priceId: row.priceId, status: 'Active' },
      });
      for (const other of others) {
        if (other.id === row.id) continue;
        other.status = 'Retired';
        await this.prices.save(other);
        await this.audit(actor.userId, 'price_retire_replaced', other.id, {
          priceId: other.priceId,
          version: other.version,
          replacedBy: row.version,
        });
      }
    }
    row.status = dto.status;
    const saved = await this.prices.save(row);
    await this.audit(actor.userId, 'price_transition', saved.id, {
      priceId: saved.priceId,
      version: saved.version,
      from,
      to: saved.status,
    });
    return this.toDto(saved);
  }

  async active(input: { serviceKey?: string; city?: string }) {
    const rows = await this.activeRows(input);
    return { rows: rows.map((row) => this.toDto(row)) };
  }

  async quote(input: { serviceKey: string; city?: string; nationality?: string }) {
    const rows = (await this.activeRows(input)).filter(
      (row) =>
        !row.nationality ||
        !input.nationality ||
        row.nationality === input.nationality,
    );
    if (rows.length === 0) {
      throw new NotFoundException('No active price for this service and city');
    }
    const currencies = new Set(rows.map((row) => row.currency));
    if (currencies.size !== 1) {
      throw new BadRequestException('Active prices use more than one currency');
    }
    const lines = rows.map((row) => ({
      priceId: row.priceId,
      version: row.version,
      itemName: row.itemName,
      pricingBasis: row.pricingBasis,
      obicFeeCents: row.obicFeeCents,
      externalFeeCents: row.externalFeeCents,
    }));
    return {
      serviceKey: input.serviceKey,
      city: input.city ?? null,
      currency: rows[0].currency,
      lines,
      totals: computeQuoteTotals(lines),
    };
  }

  /**
   * Resolve specific PriceIDs to their Active rows (registration checkout
   * basket). Returns the PriceIDs that have no active version in `missing`.
   */
  async activeLinesByPriceIds(priceIds: string[]) {
    const rows = await this.prices.find({
      where: priceIds.map((priceId) => ({ priceId, status: 'Active' as const })),
      order: { priceId: 'ASC' },
      take: 200,
    });
    const today = new Date().toISOString().slice(0, 10);
    const inWindow = rows.filter(
      (row) =>
        (!row.effectiveFrom || row.effectiveFrom <= today) &&
        (!row.effectiveTo || row.effectiveTo >= today),
    );
    const byPriceId = new Map(inWindow.map((row) => [row.priceId, row]));
    const lines: Array<{
      priceId: string;
      version: string;
      itemName: string;
      pricingBasis: string;
      obicFeeCents: number;
      externalFeeCents: number;
    }> = [];
    const missing: string[] = [];
    for (const priceId of priceIds) {
      const row = byPriceId.get(priceId);
      if (!row) {
        missing.push(priceId);
        continue;
      }
      lines.push({
        priceId: row.priceId,
        version: row.version,
        itemName: row.itemName,
        pricingBasis: row.pricingBasis,
        obicFeeCents: row.obicFeeCents,
        externalFeeCents: row.externalFeeCents,
      });
    }
    return { lines, missing };
  }

  private async activeRows(input: { serviceKey?: string; city?: string }) {
    const where: Record<string, unknown> = { status: 'Active' };
    if (input.serviceKey) where.serviceKey = input.serviceKey;
    const rows = await this.prices.find({
      where,
      order: { priceId: 'ASC' },
      take: 200,
    });
    const today = new Date().toISOString().slice(0, 10);
    return rows.filter((row) => {
      if (input.city && row.city && row.city !== input.city) return false;
      if (row.effectiveFrom && row.effectiveFrom > today) return false;
      if (row.effectiveTo && row.effectiveTo < today) return false;
      return true;
    });
  }

  private async audit(
    actorId: string,
    action: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'price_version',
        resourceId,
        meta,
      }),
    );
  }

  private toDto(row: PriceVersion) {
    return {
      id: row.id,
      priceId: row.priceId,
      version: row.version,
      serviceKey: row.serviceKey,
      itemName: row.itemName,
      city: row.city,
      nationality: row.nationality,
      obicFeeCents: row.obicFeeCents,
      externalFeeCents: row.externalFeeCents,
      currency: row.currency,
      pricingBasis: row.pricingBasis,
      status: row.status,
      effectiveFrom: row.effectiveFrom,
      effectiveTo: row.effectiveTo,
      approvedBy: row.approvedBy,
      sourceRef: row.sourceRef,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
