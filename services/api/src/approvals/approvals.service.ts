// Made by Dr Ali
// Approval templates and the requests staff open from them.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User } from '../users/user.entity';
import {
  canViewApproval,
  decidableStepIndex,
  decideApprovalStep,
  startApprovalSteps,
} from './approval-flow';
import {
  ApprovalRequest,
  ApprovalRequestStep,
  ApprovalTemplate,
  ApprovalTemplateStep,
} from './approval.entities';
import {
  CreateApprovalTemplateDto,
  DecideApprovalDto,
  OpenApprovalDto,
  UpdateApprovalTemplateDto,
} from './dto/approval.dto';

@Injectable()
export class ApprovalsService {
  constructor(
    @InjectRepository(ApprovalTemplate)
    private readonly templates: Repository<ApprovalTemplate>,
    @InjectRepository(ApprovalTemplateStep)
    private readonly templateSteps: Repository<ApprovalTemplateStep>,
    @InjectRepository(ApprovalRequest)
    private readonly requests: Repository<ApprovalRequest>,
    @InjectRepository(ApprovalRequestStep)
    private readonly requestSteps: Repository<ApprovalRequestStep>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async listTemplates(actor: AuthUser) {
    await this.requireStaff(actor);
    const rows = await this.templates.find({ order: { createdAt: 'ASC' } });
    const steps = await this.stepsForTemplates(rows.map((row) => row.id));
    const names = await this.namesFor(
      steps.map((step) => step.approverUserId),
    );
    return rows.map((row) => ({
      id: row.id,
      nameEn: row.nameEn,
      nameAr: row.nameAr,
      nameZh: row.nameZh,
      active: row.active,
      steps: steps
        .filter((step) => step.templateId === row.id)
        .sort((a, b) => a.position - b.position)
        .map((step) => ({
          position: step.position,
          approverUserId: step.approverUserId,
          approverName: names.get(step.approverUserId) ?? '',
        })),
    }));
  }

  async createTemplate(actor: AuthUser, dto: CreateApprovalTemplateDto) {
    const staff = await this.requireSuperAdmin(actor);
    const approverIds = this.uniqueIds(dto.approverIds);
    await this.requireApprovers(approverIds);
    const row = await this.templates.save(
      this.templates.create({
        nameEn: dto.nameEn.trim(),
        nameAr: dto.nameAr.trim(),
        nameZh: dto.nameZh.trim(),
        active: true,
      }),
    );
    await this.replaceTemplateSteps(row.id, approverIds);
    await this.audit(staff.id, 'admin_create_approval_template', row.id, {
      approverCount: approverIds.length,
    });
    return (await this.listTemplates(actor)).find((item) => item.id === row.id);
  }

  async updateTemplate(
    actor: AuthUser,
    id: string,
    dto: UpdateApprovalTemplateDto,
  ) {
    const staff = await this.requireSuperAdmin(actor);
    if (
      dto.nameEn === undefined &&
      dto.nameAr === undefined &&
      dto.nameZh === undefined &&
      dto.active === undefined &&
      dto.approverIds === undefined
    ) {
      throw new BadRequestException('No template changes');
    }
    const row = await this.templates.findOne({ where: { id } });
    if (!row) throw new NotFoundException('Template not found');
    if (dto.nameEn !== undefined) row.nameEn = dto.nameEn.trim();
    if (dto.nameAr !== undefined) row.nameAr = dto.nameAr.trim();
    if (dto.nameZh !== undefined) row.nameZh = dto.nameZh.trim();
    if (dto.active !== undefined) row.active = dto.active;
    await this.templates.save(row);
    if (dto.approverIds !== undefined) {
      const approverIds = this.uniqueIds(dto.approverIds);
      await this.requireApprovers(approverIds);
      await this.replaceTemplateSteps(row.id, approverIds);
    }
    await this.audit(staff.id, 'admin_update_approval_template', row.id, {
      active: row.active,
    });
    return (await this.listTemplates(actor)).find((item) => item.id === row.id);
  }

  async listRequests(actor: AuthUser) {
    const viewer = await this.requireStaff(actor);
    const role = this.staffRole(viewer);
    const rows = await this.requests.find({ order: { createdAt: 'DESC' } });
    const steps = await this.stepsForRequests(rows.map((row) => row.id));
    const visible = rows.filter((row) =>
      canViewApproval({
        viewerId: viewer.id,
        viewerRole: role,
        requesterId: row.requesterId,
        approverUserIds: steps
          .filter((step) => step.requestId === row.id)
          .map((step) => step.approverUserId),
      }),
    );
    return this.presentRequests(visible, steps, viewer.id, role);
  }

  async openRequest(actor: AuthUser, dto: OpenApprovalDto) {
    const staff = await this.requireStaff(actor);
    const template = await this.templates.findOne({
      where: { id: dto.templateId },
    });
    if (!template || !template.active) {
      throw new NotFoundException('Template not found');
    }
    const templateSteps = await this.templateSteps.find({
      where: { templateId: template.id },
      order: { position: 'ASC' },
    });
    if (templateSteps.length === 0) {
      throw new BadRequestException('Template has no approvers');
    }
    const flow = startApprovalSteps(
      templateSteps.map((step) => step.approverUserId),
    );
    const request = await this.requests.save(
      this.requests.create({
        templateId: template.id,
        requesterId: staff.id,
        title: dto.title.trim(),
        body: (dto.body ?? '').trim(),
        status: 'pending',
      }),
    );
    await this.requestSteps.save(
      flow.map((step, position) =>
        this.requestSteps.create({
          requestId: request.id,
          position,
          approverUserId: step.approverUserId,
          status: step.status,
          comment: null,
          decidedAt: null,
          decidedByUserId: null,
        }),
      ),
    );
    await this.audit(staff.id, 'approval_open', request.id, {
      templateId: template.id,
    });
    const [card] = await this.presentRequests(
      [request],
      await this.stepsForRequests([request.id]),
      staff.id,
      this.staffRole(staff),
    );
    return card;
  }

  async decide(actor: AuthUser, id: string, dto: DecideApprovalDto) {
    const staff = await this.requireStaff(actor);
    const request = await this.requests.findOne({ where: { id } });
    if (!request) throw new NotFoundException('Request not found');
    const steps = await this.requestSteps.find({
      where: { requestId: id },
      order: { position: 'ASC' },
    });
    const role = this.staffRole(staff);
    const index = decidableStepIndex({
      viewerId: staff.id,
      viewerRole: role,
      requestStatus: request.status,
      steps: steps.map((step) => ({
        approverUserId: step.approverUserId,
        status: step.status,
      })),
    });
    if (index == null) throw new ForbiddenException('Not your approval');
    let result: ReturnType<typeof decideApprovalStep>;
    try {
      result = decideApprovalStep(
        steps.map((step) => ({
          approverUserId: step.approverUserId,
          status: step.status,
        })),
        index,
        dto.decision,
      );
    } catch {
      throw new BadRequestException('This step is not waiting for a decision');
    }
    const comment = (dto.comment ?? '').trim();
    for (let i = 0; i < steps.length; i += 1) {
      const before = steps[i].status;
      const after = result.steps[i].status;
      if (before === after) continue;
      steps[i].status = after;
      if (i === index) {
        steps[i].comment = comment.length ? comment : null;
        steps[i].decidedAt = new Date();
        steps[i].decidedByUserId = staff.id;
      }
    }
    request.status = result.requestStatus;
    await this.requestSteps.save(steps);
    await this.requests.save(request);
    await this.audit(staff.id, 'approval_decide', request.id, {
      decision: dto.decision,
    });
    const [card] = await this.presentRequests(
      [request],
      steps,
      staff.id,
      role,
    );
    return card;
  }

  async cancel(actor: AuthUser, id: string) {
    const staff = await this.requireStaff(actor);
    const request = await this.requests.findOne({ where: { id } });
    if (!request) throw new NotFoundException('Request not found');
    if (request.requesterId !== staff.id) {
      throw new ForbiddenException('Only the requester can cancel');
    }
    if (request.status !== 'pending') {
      throw new BadRequestException('This request is already finished');
    }
    request.status = 'cancelled';
    await this.requests.save(request);
    await this.audit(staff.id, 'approval_cancel', request.id, {});
    const steps = await this.stepsForRequests([request.id]);
    const [card] = await this.presentRequests(
      [request],
      steps,
      staff.id,
      this.staffRole(staff),
    );
    return card;
  }

  private async presentRequests(
    rows: ApprovalRequest[],
    steps: ApprovalRequestStep[],
    viewerId: string,
    viewerRole: 'Employee' | 'SuperAdmin',
  ) {
    const templateIds = [...new Set(rows.map((row) => row.templateId))];
    const templates =
      templateIds.length === 0
        ? []
        : await this.templates.find({ where: { id: In(templateIds) } });
    const templateById = new Map(templates.map((row) => [row.id, row]));
    const userIds = [
      ...rows.map((row) => row.requesterId),
      ...steps.map((step) => step.approverUserId),
    ];
    const names = await this.namesFor(userIds);
    return rows.map((row) => {
      const mine = steps
        .filter((step) => step.requestId === row.id)
        .sort((a, b) => a.position - b.position);
      const flow = mine.map((step) => ({
        approverUserId: step.approverUserId,
        status: step.status,
      }));
      const template = templateById.get(row.templateId);
      return {
        id: row.id,
        title: row.title,
        body: row.body,
        status: row.status,
        createdAt: row.createdAt,
        requesterId: row.requesterId,
        requesterName: names.get(row.requesterId) ?? '',
        templateNameEn: template?.nameEn ?? '',
        templateNameAr: template?.nameAr ?? '',
        templateNameZh: template?.nameZh ?? '',
        canDecide:
          decidableStepIndex({
            viewerId,
            viewerRole,
            requestStatus: row.status,
            steps: flow,
          }) != null,
        canCancel: row.status === 'pending' && row.requesterId === viewerId,
        steps: mine.map((step) => ({
          position: step.position,
          approverUserId: step.approverUserId,
          approverName: names.get(step.approverUserId) ?? '',
          status: step.status,
          comment: step.comment,
        })),
      };
    });
  }

  private async stepsForTemplates(templateIds: string[]) {
    if (templateIds.length === 0) return [];
    return this.templateSteps.find({ where: { templateId: In(templateIds) } });
  }

  private async stepsForRequests(requestIds: string[]) {
    if (requestIds.length === 0) return [];
    return this.requestSteps.find({ where: { requestId: In(requestIds) } });
  }

  private async replaceTemplateSteps(templateId: string, approverIds: string[]) {
    await this.templateSteps.delete({ templateId });
    await this.templateSteps.save(
      approverIds.map((approverUserId, position) =>
        this.templateSteps.create({ templateId, position, approverUserId }),
      ),
    );
  }

  private uniqueIds(ids: string[]): string[] {
    const seen = new Set<string>();
    const out: string[] = [];
    for (const id of ids) {
      if (seen.has(id)) continue;
      seen.add(id);
      out.push(id);
    }
    if (out.length === 0) {
      throw new BadRequestException('Choose at least one approver');
    }
    return out;
  }

  private async requireApprovers(ids: string[]) {
    const rows = await this.users.find({
      where: { id: In(ids), deletedAt: IsNull() },
    });
    const ok = new Map(rows.map((row) => [row.id, row]));
    for (const id of ids) {
      const user = ok.get(id);
      if (
        !user ||
        (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
      ) {
        throw new BadRequestException('Approvers must be staff');
      }
    }
  }

  private async namesFor(ids: string[]) {
    const unique = [...new Set(ids)];
    if (unique.length === 0) return new Map<string, string>();
    const rows = await this.users.find({ where: { id: In(unique) } });
    return new Map(rows.map((row) => [row.id, row.name]));
  }

  private staffRole(user: User): 'Employee' | 'SuperAdmin' {
    return user.role === UserRole.SuperAdmin ? 'SuperAdmin' : 'Employee';
  }

  private async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (!user || user.deletedAt) throw new ForbiddenException('Staff only');
    if (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin) {
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
        resourceType: 'approval',
        resourceId,
        meta,
      }),
    );
  }
}
