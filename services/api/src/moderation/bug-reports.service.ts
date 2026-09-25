// Made by Dr Ali
// App bug reports — customers submit; Employee + SuperAdmin review.

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
import { User } from '../users/user.entity';
import { BugReport, BugReportStatus } from './bug-report.entity';

@Injectable()
export class BugReportsService {
  constructor(
    @InjectRepository(BugReport)
    private readonly reports: Repository<BugReport>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  async create(
    actor: AuthUser,
    input: { description: string; photoUrls?: string[] },
  ) {
    const description = (input.description ?? '').trim();
    if (description.length < 5) {
      throw new BadRequestException('Description too short');
    }
    const photos = (input.photoUrls ?? [])
      .map((u) => (typeof u === 'string' ? u.trim() : ''))
      .filter((u) => u.startsWith('/') || u.startsWith('http'))
      .slice(0, 6);
    const saved = await this.reports.save(
      this.reports.create({
        userId: actor.userId,
        description: description.slice(0, 4000),
        photoUrls: photos,
        status: BugReportStatus.Open,
      }),
    );
    return this.toDto(saved);
  }

  async listMine(actor: AuthUser) {
    const rows = await this.reports.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
    return rows.map((r) => this.toDto(r));
  }

  /** Staff desk — Employee + SuperAdmin. */
  async listForStaff(actor: AuthUser) {
    this.requireStaff(actor);
    const rows = await this.reports.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
    const userIds = [...new Set(rows.map((r) => r.userId))];
    const users = userIds.length
      ? await this.users.find({ where: { id: In(userIds) } })
      : [];
    const byId = new Map(users.map((u) => [u.id, u]));
    return rows.map((r) => {
      const u = byId.get(r.userId);
      return {
        ...this.toDto(r),
        userName: u?.name ?? null,
        userEmail: u?.email ?? null,
        userPhone: u?.phone ?? null,
      };
    });
  }

  async getOne(actor: AuthUser, id: string) {
    this.requireStaff(actor);
    const row = await this.reports.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Bug report not found');
    const u = await this.users.findOne({ where: { id: row.userId } });
    return {
      ...this.toDto(row),
      userName: u?.name ?? null,
      userEmail: u?.email ?? null,
      userPhone: u?.phone ?? null,
    };
  }

  async updateStatus(actor: AuthUser, id: string, status: BugReportStatus) {
    this.requireStaff(actor);
    if (!Object.values(BugReportStatus).includes(status)) {
      throw new BadRequestException('Invalid status');
    }
    const row = await this.reports.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Bug report not found');
    row.status = status;
    row.reviewedBy = actor.userId;
    row.reviewedAt = new Date();
    const saved = await this.reports.save(row);
    return this.toDto(saved);
  }

  private requireStaff(actor: AuthUser) {
    if (
      actor.role !== UserRole.Employee &&
      actor.role !== UserRole.SuperAdmin
    ) {
      throw new ForbiddenException('Staff only');
    }
  }

  private toDto(row: BugReport) {
    return {
      id: row.id,
      userId: row.userId,
      description: row.description,
      photoUrls: Array.isArray(row.photoUrls) ? row.photoUrls : [],
      status: row.status,
      reviewedBy: row.reviewedBy,
      reviewedAt: row.reviewedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
