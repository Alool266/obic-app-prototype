// Made by Dr Ali
// Company directory: departments, who can see whom, and the staff list.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User } from '../users/user.entity';
import { Department } from './department.entity';
import { CreateDepartmentDto, UpdateDepartmentDto } from './dto/department.dto';
import {
  canSeeDirectoryMember,
  directoryShowsContact,
  isDirectoryVisibility,
  type DirectoryViewer,
} from './directory-visibility';

export type DirectoryDepartmentDto = {
  id: string;
  nameEn: string;
  nameAr: string;
  nameZh: string;
  branchLabel: string | null;
  visibility: string;
  sortOrder: number;
};

export type DirectoryCard = {
  id: string;
  name: string;
  staffTitle: string | null;
  branchLabel: string | null;
  departmentId: string | null;
  departmentNameEn: string | null;
  departmentNameAr: string | null;
  departmentNameZh: string | null;
  avatarUrl: string | null;
  phone: string | null;
  email: string | null;
};

@Injectable()
export class DirectoryService {
  constructor(
    @InjectRepository(Department)
    private readonly departments: Repository<Department>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async listDepartments(actor: AuthUser): Promise<DirectoryDepartmentDto[]> {
    await this.requireStaff(actor);
    const rows = await this.departments.find({
      order: { sortOrder: 'ASC', nameEn: 'ASC' },
    });
    return rows.map((row) => this.toDepartmentDto(row));
  }

  async listDirectory(actor: AuthUser): Promise<DirectoryCard[]> {
    const viewerUser = await this.requireStaff(actor);
    const viewer = this.toViewer(viewerUser);
    const [people, departments] = await Promise.all([
      this.users.find({
        where: [
          { role: UserRole.Employee, deletedAt: IsNull() },
          { role: UserRole.SuperAdmin, deletedAt: IsNull() },
        ],
        order: { name: 'ASC' },
      }),
      this.departments.find(),
    ]);
    const byId = new Map(departments.map((row) => [row.id, row]));

    return people
      .filter((person) => {
        const department = person.departmentId
          ? byId.get(person.departmentId)
          : undefined;
        return canSeeDirectoryMember(viewer, {
          id: person.id,
          branchLabel: person.branchLabel,
          departmentId: department ? person.departmentId : null,
          departmentVisibility:
            department && isDirectoryVisibility(department.visibility)
              ? department.visibility
              : null,
        });
      })
      .map((person) => {
        const department = person.departmentId
          ? byId.get(person.departmentId)
          : undefined;
        const showContact = directoryShowsContact(viewer, person.id);
        return {
          id: person.id,
          name: person.name,
          staffTitle: person.staffTitle ?? null,
          branchLabel: person.branchLabel ?? null,
          departmentId: department ? person.departmentId : null,
          departmentNameEn: department?.nameEn ?? null,
          departmentNameAr: department?.nameAr ?? null,
          departmentNameZh: department?.nameZh ?? null,
          avatarUrl: person.avatarUrl ?? null,
          phone: showContact ? person.phone : null,
          email: showContact ? person.email : null,
        };
      });
  }

  async createDepartment(
    actor: AuthUser,
    dto: CreateDepartmentDto,
  ): Promise<DirectoryDepartmentDto> {
    const staff = await this.requireSuperAdmin(actor);
    const row = await this.departments.save(
      this.departments.create({
        nameEn: dto.nameEn.trim(),
        nameAr: dto.nameAr.trim(),
        nameZh: dto.nameZh.trim(),
        branchLabel: this.cleanBranch(dto.branchLabel),
        visibility: dto.visibility,
        sortOrder: dto.sortOrder ?? 0,
      }),
    );
    await this.audit(staff.id, 'admin_create_department', row.id, {
      visibility: row.visibility,
      branchLabel: row.branchLabel,
    });
    return this.toDepartmentDto(row);
  }

  async updateDepartment(
    actor: AuthUser,
    id: string,
    dto: UpdateDepartmentDto,
  ): Promise<DirectoryDepartmentDto> {
    const staff = await this.requireSuperAdmin(actor);
    const row = await this.requireDepartment(id);
    if (dto.nameEn !== undefined) row.nameEn = dto.nameEn.trim();
    if (dto.nameAr !== undefined) row.nameAr = dto.nameAr.trim();
    if (dto.nameZh !== undefined) row.nameZh = dto.nameZh.trim();
    if (dto.branchLabel !== undefined) {
      row.branchLabel = this.cleanBranch(dto.branchLabel);
    }
    if (dto.visibility !== undefined) row.visibility = dto.visibility;
    if (dto.sortOrder !== undefined) row.sortOrder = dto.sortOrder;
    const saved = await this.departments.save(row);
    await this.audit(staff.id, 'admin_update_department', saved.id, {
      visibility: saved.visibility,
      branchLabel: saved.branchLabel,
    });
    return this.toDepartmentDto(saved);
  }

  async deleteDepartment(actor: AuthUser, id: string): Promise<{ ok: true }> {
    const staff = await this.requireSuperAdmin(actor);
    const row = await this.requireDepartment(id);
    await this.departments.remove(row);
    await this.audit(staff.id, 'admin_delete_department', id, {
      nameEn: row.nameEn,
    });
    return { ok: true };
  }

  async requireDepartment(id: string): Promise<Department> {
    const row = await this.departments.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Department not found');
    return row;
  }

  private toViewer(user: User): DirectoryViewer {
    if (user.role === UserRole.SuperAdmin) {
      return {
        id: user.id,
        role: 'SuperAdmin',
        branchLabel: user.branchLabel,
        departmentId: user.departmentId,
      };
    }
    return {
      id: user.id,
      role: 'Employee',
      branchLabel: user.branchLabel,
      departmentId: user.departmentId,
    };
  }

  private toDepartmentDto(row: Department): DirectoryDepartmentDto {
    return {
      id: row.id,
      nameEn: row.nameEn,
      nameAr: row.nameAr,
      nameZh: row.nameZh,
      branchLabel: row.branchLabel,
      visibility: row.visibility,
      sortOrder: row.sortOrder,
    };
  }

  private cleanBranch(value: string | null | undefined): string | null {
    const trimmed = (value ?? '').trim();
    return trimmed.length ? trimmed : null;
  }

  private async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (!user || user.deletedAt) {
      throw new ForbiddenException('Staff only');
    }
    if (
      user.role !== UserRole.Employee &&
      user.role !== UserRole.SuperAdmin
    ) {
      throw new ForbiddenException('Staff only');
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
    resourceId: string,
    meta: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'department',
        resourceId,
        meta,
      }),
    );
  }
}

// Keep a named error for empty updates so the controller can reject them.
export function assertDepartmentUpdate(dto: UpdateDepartmentDto): void {
  if (
    dto.nameEn === undefined &&
    dto.nameAr === undefined &&
    dto.nameZh === undefined &&
    dto.branchLabel === undefined &&
    dto.visibility === undefined &&
    dto.sortOrder === undefined
  ) {
    throw new BadRequestException('No department changes');
  }
}
