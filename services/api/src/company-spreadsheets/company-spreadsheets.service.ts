// Made by Dr Ali
// Shared spreadsheets. Staff edit the cells. Customers receive 403.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import {
  assertSheetGrid,
  emptySheetGrid,
  SHEET_COLS,
  SHEET_LIMIT,
  SHEET_ROWS,
  normalizeSheetTitle,
  sheetTitleKey,
} from './company-spreadsheet';
import { CompanySpreadsheet } from './company-spreadsheet.entity';
import { SaveSheetDto, SaveSheetGridDto } from './dto/company-spreadsheet.dto';

const listColumns = {
  id: true,
  title: true,
  active: true,
  updatedBy: true,
  updatedAt: true,
} as const;

@Injectable()
export class CompanySpreadsheetsService {
  constructor(
    @InjectRepository(CompanySpreadsheet)
    private readonly sheets: Repository<CompanySpreadsheet>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    await this.requireStaff(actor);
    const rows = await this.sheets.find({
      where: { active: true },
      order: { title: 'ASC' },
      take: SHEET_LIMIT,
      select: listColumns,
    });
    const names = await this.namesFor(rows.map((row) => row.updatedBy));
    return { rows: rows.map((row) => this.toListCard(row, names)), columns: SHEET_COLS, rowCount: SHEET_ROWS };
  }

  async one(actor: AuthUser, id: string) {
    await this.requireStaff(actor);
    const row = await this.requireSheet(id);
    if (!row.active) throw new BadRequestException('This spreadsheet is paused');
    const names = await this.namesFor([row.updatedBy]);
    return this.toCard(row, names);
  }

  async updateGrid(actor: AuthUser, id: string, dto: SaveSheetGridDto) {
    const user = await this.requireStaff(actor);
    const row = await this.requireSheet(id);
    if (!row.active) throw new BadRequestException('This spreadsheet is paused');
    try {
      row.grid = assertSheetGrid(dto.rows);
    } catch (error) {
      throw this.statusError(error);
    }
    row.updatedBy = user.id;
    const saved = await this.sheets.save(row);
    await this.audit(user.id, 'company_spreadsheet_update', saved.id, { title: saved.title });
    const names = await this.namesFor([saved.updatedBy]);
    return this.toCard(saved, names);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.sheets.find({
      order: { title: 'ASC' },
      take: SHEET_LIMIT,
      select: listColumns,
    });
    const names = await this.namesFor(rows.map((row) => row.updatedBy));
    return {
      rows: rows.map((row) => ({ ...this.toListCard(row, names), active: row.active })),
      columns: SHEET_COLS,
      rowCount: SHEET_ROWS,
    };
  }

  async adminOne(actor: AuthUser, id: string) {
    await this.requireReviewer(actor);
    const row = await this.requireSheet(id);
    const names = await this.namesFor([row.updatedBy]);
    return { ...this.toCard(row, names), active: row.active };
  }

  async saveAdmin(actor: AuthUser, dto: SaveSheetDto, id?: string) {
    const user = await this.requireSuperAdmin(actor);
    if (!id) {
      const count = await this.sheets.count();
      if (count >= SHEET_LIMIT) throw new BadRequestException('The company already has 20 spreadsheets');
    }
    const row = id
      ? await this.requireSheet(id)
      : this.sheets.create({
          title: 'pending',
          titleKey: 'pending',
          grid: emptySheetGrid(),
          active: true,
          updatedBy: user.id,
        });
    try {
      const title = normalizeSheetTitle(dto.title);
      row.title = title;
      row.titleKey = sheetTitleKey(title);
      if (dto.rows) row.grid = assertSheetGrid(dto.rows);
      else if (!id) row.grid = emptySheetGrid();
      if (typeof dto.active === 'boolean') row.active = dto.active;
    } catch (error) {
      throw this.statusError(error);
    }
    row.updatedBy = user.id;
    let saved: CompanySpreadsheet;
    try {
      saved = await this.sheets.save(row);
    } catch (error) {
      if (isUniqueViolation(error)) throw new BadRequestException('That spreadsheet already exists');
      throw error;
    }
    await this.audit(user.id, id ? 'company_spreadsheet_update' : 'company_spreadsheet_create', saved.id, {
      title: saved.title,
    });
    const names = await this.namesFor([saved.updatedBy]);
    return { ...this.toCard(saved, names), active: saved.active };
  }

  private toListCard(
    row: Pick<CompanySpreadsheet, 'id' | 'title' | 'updatedBy' | 'updatedAt'>,
    names: Map<string, string>,
  ) {
    return {
      id: row.id,
      title: row.title,
      editorName: names.get(row.updatedBy) ?? null,
      updatedAt: row.updatedAt,
    };
  }

  private toCard(row: CompanySpreadsheet, names: Map<string, string>) {
    return {
      ...this.toListCard(row, names),
      columns: SHEET_COLS,
      rowCount: SHEET_ROWS,
      rows: this.gridOf(row.grid),
    };
  }

  private gridOf(value: unknown): string[][] {
    try {
      return assertSheetGrid(value);
    } catch (error) {
      const code = error instanceof Error ? error.message : '';
      if (code === 'SHEET_GRID' || code === 'SHEET_CELL') return emptySheetGrid();
      throw error;
    }
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private async requireSheet(id: string): Promise<CompanySpreadsheet> {
    const row = await this.sheets.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This spreadsheet was not found');
    return row;
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'SHEET_TITLE':
        return new BadRequestException('Enter a title up to 40 characters');
      case 'SHEET_GRID':
        return new BadRequestException('Use 12 rows and 6 columns');
      case 'SHEET_CELL':
        return new BadRequestException('Each cell can be up to 80 characters');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the spreadsheet');
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

  private async audit(actorId: string, action: string, resourceId: string, meta: Record<string, unknown>) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'company_spreadsheet',
        resourceId,
        meta,
      }),
    );
  }
}

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
