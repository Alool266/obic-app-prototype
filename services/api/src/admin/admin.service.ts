// Made by Dr Ali
// Phase 4 Admin service — least privilege; DB role; assignment scope; audit every oversight.

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { IsNull, Not, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { ChatService } from '../chat/chat.service';
import { adminRequireTotp } from '../common/admin-security';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { AiConfig } from '../ai/ai.config';
import { AiSettingsService } from '../ai/ai-settings.service';
import { NotificationKind } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order, OrderStatus } from '../orders/order.entity';
import { OrderChatService } from '../orders/order-chat.service';
import { User } from '../users/user.entity';
import {
  canManageOffers,
  canOpenInternalOps,
  toPublicUser,
} from '../users/user.mapper';
import {
  AdminAiSettingsDto,
  AdminCreateStaffDto,
  AdminUpdateOrderDto,
  AdminUpdateStaffProfileDto,
  AdminUpdateStaffRoleDto,
} from './dto/admin.dto';
import {
  canReassignOrders,
  isAllowedStatusTransition,
  orderInReassignScope,
  waitingCustomerNotifyBody,
} from '../org/form2-workflow';

const BCRYPT_ROUNDS = 12;

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
    private readonly chat: ChatService,
    private readonly notifications: NotificationsService,
    private readonly orderChat: OrderChatService,
    private readonly config: ConfigService,
    private readonly aiConfig: AiConfig,
    private readonly aiSettings: AiSettingsService,
  ) {}

  /** Staff gate — role from DB, never JWT alone. */
  async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (!user) throw new ForbiddenException('Insufficient role');
    if (
      user.role !== UserRole.Employee &&
      user.role !== UserRole.SuperAdmin
    ) {
      throw new ForbiddenException('Staff only');
    }
    return user;
  }

  async requireSuperAdmin(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (user.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
    return user;
  }

  async me(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const isSa = user.role === UserRole.SuperAdmin;
    const totpEnabled = user.totpEnabled === true && !!user.totpSecretEnc;
    const totpPolicyRequired = adminRequireTotp(this.config);
    return {
      ...toPublicUser(user),
      isStaff: true,
      isSuperAdmin: isSa,
      /** Effective Ops gate for Me / hub entry (SuperAdmin always true). */
      canOpenOps: canOpenInternalOps(user),
      /** Effective offers gate for hotel/flight desk (SuperAdmin always true). */
      canManageOffers: canManageOffers(user),
      /** SuperAdmin authenticator enrollment. */
      totpEnabled: isSa ? totpEnabled : false,
      /** When true, SuperAdmin must enroll before other Admin routes. */
      totpEnrollRequired: isSa && totpPolicyRequired && !totpEnabled,
      /** Privileged staff mutations need X-OBIC-TOTP when TOTP is on / required. */
      totpStepUpRequired: isSa && (totpPolicyRequired || totpEnabled),
      /**
       * Form2 rule 4 — SuperAdmin, or Employee with branch-manager / sales-rep
       * staffTitle (desk label ACL).
       */
      canReassignOrders: canReassignOrders(user),
      /** Form2 rule 5 — SuperAdmin may create staff from Admin. */
      canAddStaff: isSa,
    };
  }

  async dashboard(actor: AuthUser) {
    const staff = await this.requireStaff(actor);
    const isSa = staff.role === UserRole.SuperAdmin;

    const orderWhere = isSa
      ? {}
      : { assignedEmployeeId: staff.id };

    const [orderTotal, submitted, assigned, inProgress, waitingCustomer, unassigned] =
      await Promise.all([
      this.orders.count({ where: orderWhere }),
      this.orders.count({
        where: isSa
          ? { status: OrderStatus.Submitted }
          : { status: OrderStatus.Submitted, assignedEmployeeId: staff.id },
      }),
      this.orders.count({
        where: isSa
          ? { status: OrderStatus.Assigned }
          : { status: OrderStatus.Assigned, assignedEmployeeId: staff.id },
      }),
      this.orders.count({
        where: isSa
          ? { status: OrderStatus.InProgress }
          : { status: OrderStatus.InProgress, assignedEmployeeId: staff.id },
      }),
      this.orders.count({
        where: isSa
          ? { status: OrderStatus.WaitingCustomer }
          : {
              status: OrderStatus.WaitingCustomer,
              assignedEmployeeId: staff.id,
            },
      }),
      isSa
        ? this.orders.count({ where: { assignedEmployeeId: IsNull() } })
        : Promise.resolve(0),
    ]);

    await this.writeAudit(staff.id, 'admin_dashboard', 'admin', null, {
      role: staff.role,
    });

    return {
      role: staff.role,
      orders: {
        total: orderTotal,
        submitted,
        assigned,
        inProgress,
        waitingCustomer,
        unassigned: isSa ? unassigned : undefined,
      },
    };
  }

  async listOrders(actor: AuthUser) {
    const staff = await this.requireStaff(actor);
    const isSa = staff.role === UserRole.SuperAdmin;
    const reassign = canReassignOrders(staff);

    let where:
      | Record<string, unknown>
      | Array<Record<string, unknown>> = { assignedEmployeeId: staff.id };

    if (isSa) {
      where = {};
    } else if (reassign) {
      const branch = (staff.branchLabel ?? '').trim();
      // Assigned queue + same-branch pool for off-duty reassignment (Form2 rule 4).
      where = branch
        ? [
            { assignedEmployeeId: staff.id },
            { preferredBranch: branch },
          ]
        : { assignedEmployeeId: staff.id };
    }

    const rows = await this.orders.find({
      where,
      relations: { service: true, user: true, assignedEmployee: true },
      order: { createdAt: 'DESC' },
      take: 200,
    });

    const chatMap = await this.orderChat.conversationIdsForOrders(
      rows.map((r) => r.id),
    );
    return rows.map((o) => this.orderDto(o, chatMap.get(o.id) ?? null));
  }

  async updateOrder(actor: AuthUser, orderId: string, dto: AdminUpdateOrderDto) {
    const staff = await this.requireStaff(actor);
    const isSa = staff.role === UserRole.SuperAdmin;
    const reassign = canReassignOrders(staff);

    const order = await this.orders.findOne({
      where: { id: orderId },
      relations: { service: true, user: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    const assignedToSelf = order.assignedEmployeeId === staff.id;
    const inReassignScope = orderInReassignScope(order, staff);

    // Visibility: assignee, SuperAdmin, or Form2 reassign role on same branch.
    if (!isSa && !assignedToSelf && !(reassign && inReassignScope)) {
      throw new NotFoundException('Order not found');
    }

    const statusBefore = order.status;

    if (dto.assignedEmployeeId !== undefined) {
      // Form2 rule 4: SuperAdmin, or sales-rep / branch manager in branch scope.
      if (!isSa && !(reassign && inReassignScope)) {
        throw new ForbiddenException(
          'Only SuperAdmin, branch manager, or sales rep can reassign orders',
        );
      }
      if (dto.assignedEmployeeId === null) {
        order.assignedEmployeeId = null;
      } else {
        const emp = await this.users.findOne({
          where: { id: dto.assignedEmployeeId },
        });
        if (!emp || emp.role !== UserRole.Employee) {
          throw new BadRequestException('Assignee must be an Employee');
        }
        order.assignedEmployeeId = emp.id;
      }
      if (
        order.status === OrderStatus.Submitted &&
        order.assignedEmployeeId
      ) {
        order.status = OrderStatus.Assigned;
      }
    }

    if (dto.status !== undefined) {
      // Form2 rule 1: assigned Employee may change status alone; SuperAdmin too.
      // Close (Completed/Cancelled) from mobile Admin + Admin web — same path (rule 3).
      if (!isSa && !assignedToSelf) {
        throw new ForbiddenException(
          'Only the assigned employee can change order status',
        );
      }
      if (
        !isSa &&
        !isAllowedStatusTransition(statusBefore, dto.status)
      ) {
        throw new BadRequestException(
          `Invalid status transition: ${statusBefore} → ${dto.status}`,
        );
      }
      order.status = dto.status;
    }

    const saved = await this.orders.save(order);
    const conversationId = await this.orderChat.ensureForOrder(saved);
    const statusChanged = saved.status !== statusBefore;
    if (statusChanged) {
      await this.orderChat.postStatusNote(
        conversationId,
        staff.id,
        saved.status,
      );
    }
    await this.writeAudit(staff.id, 'admin_update_order', 'order', orderId, {
      status: saved.status,
      assignedEmployeeId: saved.assignedEmployeeId,
    });

    if (statusChanged && saved.userId) {
      const statusBody =
        saved.status === OrderStatus.WaitingCustomer
          ? waitingCustomerNotifyBody()
          : `Your order is now ${saved.status}`;
      await this.notifications.createForUsers({
        userIds: [saved.userId],
        kind: NotificationKind.OrderStatus,
        title: 'Order status updated',
        body: statusBody,
        data: {
          type: 'order_status',
          orderId: saved.id,
          status: saved.status,
        },
      });
    }

    const fresh = await this.orders.findOne({
      where: { id: saved.id },
      relations: { service: true, user: true, assignedEmployee: true },
    });
    const chatId = await this.orderChat.conversationIdForOrder(saved.id);
    return this.orderDto(fresh!, chatId);
  }

  async openOrderChat(actor: AuthUser, orderId: string) {
    await this.requireStaff(actor);
    return this.orderChat.openForActor(actor, orderId);
  }

  async listStaff(actor: AuthUser) {
    const staff = await this.requireStaff(actor);
    const isSa = staff.role === UserRole.SuperAdmin;
    const reassign = canReassignOrders(staff);

    // SuperAdmin: full directory. Reassign ACL: Employees only (pick assignee).
    if (!isSa && !reassign) {
      throw new ForbiddenException('SuperAdmin or reassign role only');
    }

    const rows = await this.users.find({
      where: isSa
        ? [
            { role: UserRole.Employee, deletedAt: IsNull() },
            { role: UserRole.SuperAdmin, deletedAt: IsNull() },
          ]
        : { role: UserRole.Employee, deletedAt: IsNull() },
      order: { createdAt: 'ASC' },
    });
    await this.writeAudit(actor.userId, 'admin_list_staff', 'user', null, {
      count: rows.length,
      scope: isSa ? 'full' : 'reassign_directory',
    });
    return rows.map((u) => toPublicUser(u));
  }

  /**
   * Soft-deleted / deactivated accounts — SuperAdmin or Employee with Ops ACL.
   */
  async listDeactivatedUsers(actor: AuthUser, q?: string) {
    const staff = await this.requireStaff(actor);
    if (!canOpenInternalOps(staff)) {
      throw new ForbiddenException('SuperAdmin or Ops staff only');
    }

    const qb = this.users
      .createQueryBuilder('u')
      .where('u.deletedAt IS NOT NULL')
      .orderBy('u.deletedAt', 'DESC')
      .take(200);

    const needle = (q ?? '').trim();
    if (needle.length) {
      qb.andWhere(
        '(u.email ILIKE :q OR u.phone ILIKE :q OR u.name ILIKE :q OR u.obicId ILIKE :q)',
        { q: `%${needle}%` },
      );
    }

    const rows = await qb.getMany();
    await this.writeAudit(
      actor.userId,
      'admin_list_deactivated',
      'user',
      null,
      { count: rows.length, q: needle.length ? true : false },
    );
    return rows.map((u) => ({
      ...toPublicUser(u),
      deletedAt: u.deletedAt,
    }));
  }

  /**
   * Clear deletedAt so the user can sign in again with the same password.
   */
  async restoreUser(actor: AuthUser, userId: string) {
    const staff = await this.requireStaff(actor);
    if (!canOpenInternalOps(staff)) {
      throw new ForbiddenException('SuperAdmin or Ops staff only');
    }

    const target = await this.users.findOne({ where: { id: userId } });
    if (!target) throw new NotFoundException('User not found');
    if (!target.deletedAt) {
      throw new BadRequestException('Account is already active');
    }

    target.deletedAt = null;
    await this.users.save(target);
    await this.writeAudit(staff.id, 'admin_restore_user', 'user', userId, {
      email: Boolean(target.email),
      phone: Boolean(target.phone),
      role: target.role,
    });
    return {
      ...toPublicUser(target),
      deletedAt: null as Date | null,
    };
  }

  /**
   * Form2 rule 5 — SuperAdmin creates Employee accounts from Admin.
   * Production mobiles/emails are entered later via this same Staff UI.
   */
  async createStaff(actor: AuthUser, dto: AdminCreateStaffDto) {
    const sa = await this.requireSuperAdmin(actor);

    const email = dto.email?.trim().toLowerCase() || null;
    const phoneRaw = dto.phone?.trim() || null;
    const phone = phoneRaw && phoneRaw.length ? phoneRaw : null;

    if (!email && !phone) {
      throw new BadRequestException('Email or phone is required');
    }

    if (email) {
      const taken = await this.users.findOne({ where: { email } });
      if (taken) throw new ConflictException('Email already in use');
    }
    if (phone) {
      const taken = await this.users.findOne({ where: { phone } });
      if (taken) throw new ConflictException('Phone already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const title = (dto.staffTitle ?? '').toString().trim();
    const branch = (dto.branchLabel ?? '').toString().trim();

    const user = this.users.create({
      name: dto.name.trim(),
      email,
      phone,
      passwordHash,
      role: UserRole.Employee,
      staffTitle: title.length ? title : null,
      branchLabel: branch.length ? branch : null,
      opsAccess: false,
      offersAccess: false,
    });
    await this.users.save(user);

    await this.writeAudit(sa.id, 'admin_create_staff', 'user', user.id, {
      email: Boolean(email),
      phone: Boolean(phone),
      staffTitle: user.staffTitle,
      branchLabel: user.branchLabel,
    });

    return toPublicUser(user);
  }

  async updateStaffRole(
    actor: AuthUser,
    targetUserId: string,
    dto: AdminUpdateStaffRoleDto,
  ) {
    const sa = await this.requireSuperAdmin(actor);

    // Cannot change own role via this path (prevent lockout / self-escalation theater).
    if (targetUserId === sa.id) {
      throw new ForbiddenException('Cannot change your own role here');
    }

    const target = await this.users.findOne({ where: { id: targetUserId } });
    if (!target) throw new NotFoundException('User not found');

    const before = target.role;
    // Only allow Customer ↔ Employee ↔ SuperAdmin via SuperAdmin; still audited.
    if (!Object.values(UserRole).includes(dto.role)) {
      throw new BadRequestException('Invalid role');
    }
    target.role = dto.role;
    // Desk labels are staff-only; clear if demoted to Customer (AuthZ is role).
    if (dto.role === UserRole.Customer) {
      target.staffTitle = null;
      target.branchLabel = null;
      target.opsAccess = false;
      target.offersAccess = false;
    } else if (dto.role === UserRole.SuperAdmin) {
      // SuperAdmin always has Ops + offers — keep DB aligned for staff desk display.
      target.opsAccess = true;
      target.offersAccess = true;
    }
    await this.users.save(target);

    await this.writeAudit(sa.id, 'admin_change_role', 'user', targetUserId, {
      from: before,
      to: dto.role,
    });

    return toPublicUser(target);
  }

  /**
   * SuperAdmin updates staff display fields / temp desk labels / optional password.
   * Security: never changes role here (use updateStaffRole); bcrypt for password;
   * phone uniqueness; audit without logging the new password.
   */
  async updateStaffProfile(
    actor: AuthUser,
    targetUserId: string,
    dto: AdminUpdateStaffProfileDto,
  ) {
    const sa = await this.requireSuperAdmin(actor);
    const target = await this.users.findOne({ where: { id: targetUserId } });
    if (!target) throw new NotFoundException('User not found');

    // Only staff rows (Employee / SuperAdmin). Customers stay on customer APIs.
    if (
      target.role !== UserRole.Employee &&
      target.role !== UserRole.SuperAdmin
    ) {
      throw new ForbiddenException('Target is not staff');
    }

    const changes: Record<string, unknown> = {};

    if (dto.name !== undefined) {
      const name = dto.name.trim();
      if (name.length < 2) throw new BadRequestException('Name too short');
      target.name = name;
      changes.name = true;
    }

    if (dto.phone !== undefined) {
      const phone = dto.phone.trim();
      if (phone.length === 0) {
        target.phone = null;
      } else {
        const taken = await this.users.findOne({
          where: { phone, id: Not(target.id) },
        });
        if (taken) throw new ConflictException('Phone already in use');
        target.phone = phone;
      }
      changes.phone = true;
    }

    if (dto.staffTitle !== undefined) {
      const v = (dto.staffTitle ?? '').toString().trim();
      target.staffTitle = v.length ? v : null;
      changes.staffTitle = true;
    }

    if (dto.branchLabel !== undefined) {
      const v = (dto.branchLabel ?? '').toString().trim();
      target.branchLabel = v.length ? v : null;
      changes.branchLabel = true;
    }

    if (dto.avatarUrl !== undefined) {
      const v = (dto.avatarUrl ?? '').toString().trim();
      target.avatarUrl = v.length ? v : null;
      changes.avatarUrl = true;
    }

    if (dto.opsAccess !== undefined) {
      // SuperAdmin always has Ops; do not let a false flip remove their access.
      if (target.role === UserRole.SuperAdmin) {
        target.opsAccess = true;
      } else if (target.role === UserRole.Employee) {
        target.opsAccess = Boolean(dto.opsAccess);
        changes.opsAccess = target.opsAccess;
      }
    }

    if (dto.offersAccess !== undefined) {
      // SuperAdmin always may manage offers; do not let a false flip remove access.
      if (target.role === UserRole.SuperAdmin) {
        target.offersAccess = true;
      } else if (target.role === UserRole.Employee) {
        target.offersAccess = Boolean(dto.offersAccess);
        changes.offersAccess = target.offersAccess;
      }
    }

    if (dto.newPassword !== undefined) {
      const pw = dto.newPassword;
      if (pw.length < 8) {
        throw new BadRequestException('Password must be at least 8 characters');
      }
      target.passwordHash = await bcrypt.hash(pw, BCRYPT_ROUNDS);
      changes.passwordReset = true;
    }

    await this.users.save(target);
    await this.writeAudit(sa.id, 'admin_update_staff_profile', 'user', targetUserId, {
      changes,
    });

    return toPublicUser(target);
  }

  async listEmployeeChats(
    actor: AuthUser,
    filters?: {
      kind?: string;
      q?: string;
      from?: string;
      to?: string;
      includeFriends?: boolean;
    },
  ) {
    await this.requireSuperAdmin(actor);
    return this.chat.listEmployeeChats(actor, filters);
  }

  async readTranscript(actor: AuthUser, conversationId: string) {
    await this.requireSuperAdmin(actor);
    return this.chat.adminReadTranscript(actor, conversationId);
  }

  async joinOversightChat(actor: AuthUser, conversationId: string) {
    await this.requireSuperAdmin(actor);
    return this.chat.adminJoinThread(actor, conversationId);
  }

  async listAudit(actor: AuthUser, limit = 100) {
    await this.requireSuperAdmin(actor);
    const take = Math.min(Math.max(limit, 1), 200);
    return this.auditLogs.find({
      order: { createdAt: 'DESC' },
      take,
    });
  }

  /** SuperAdmin: global AI auto-reply flag + AI status (no keys). */
  async getAiSettings(actor: AuthUser) {
    await this.requireSuperAdmin(actor);
    const globalAutoReplyEnabled =
      await this.aiSettings.getGlobalAutoReplyFlag();
    return {
      aiEnabled: this.aiConfig.enabled,
      envAutoReplyEnabled: this.aiConfig.autoReplyEnabled,
      globalAutoReplyEnabled,
      /** Effective for new customer messages on support/order threads. */
      effectiveAutoReplyEnabled:
        this.aiConfig.autoReplyEnabled && globalAutoReplyEnabled,
      provider: this.aiConfig.enabled ? this.aiConfig.provider : null,
      model: this.aiConfig.enabled ? this.aiConfig.model : null,
    };
  }

  async setAiSettings(actor: AuthUser, dto: AdminAiSettingsDto) {
    await this.requireSuperAdmin(actor);
    const prev = await this.aiSettings.getGlobalAutoReplyFlag();
    const next = await this.aiSettings.setGlobalAutoReplyFlag(
      dto.globalAutoReplyEnabled,
    );
    await this.writeAudit(
      actor.userId,
      'ai_auto_reply_global',
      'app_setting',
      'ai_auto_reply_global',
      { enabled: next, previous: prev },
    );
    return this.getAiSettings(actor);
  }

  private orderDto(o: Order, conversationId?: string | null) {
    return {
      id: o.id,
      userId: o.userId,
      customerName: o.user?.name ?? null,
      customerEmail: o.user?.email ?? null,
      customerPhone: o.user?.phone ?? null,
      serviceId: o.serviceId,
      serviceSlug: o.service?.slug ?? null,
      serviceTitleEn: o.service?.nameEn ?? null,
      serviceTitleAr: o.service?.nameAr ?? null,
      serviceTitleZh: o.service?.nameZh ?? null,
      subServiceId: o.subServiceId ?? null,
      subServiceNameEn: o.subServiceNameEn ?? null,
      subServiceNameAr: o.subServiceNameAr ?? null,
      formData: o.formData ?? null,
      offerId: o.offerId ?? null,
      status: o.status,
      preferredBranch: o.preferredBranch,
      notes: o.notes,
      assignedEmployeeId: o.assignedEmployeeId,
      assignedEmployeeName: o.assignedEmployee?.name ?? null,
      assignedEmployeeTitle: o.assignedEmployee?.staffTitle ?? null,
      conversationId: conversationId ?? null,
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
    };
  }

  private async writeAudit(
    actorId: string,
    action: string,
    resourceType: string,
    resourceId: string | null,
    meta?: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType,
        resourceId,
        meta: meta ?? null,
      }),
    );
  }
}
