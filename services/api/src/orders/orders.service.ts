// Made by Dr Ali
// Orders — create/list for the authenticated user only (JWT subject).
// Optional offerId links a hotel/flight request and notifies offers staff.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import {
  NotificationKind,
} from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { ServicesService } from '../services/services.service';
import { User } from '../users/user.entity';
import { canManageOffers } from '../users/user.mapper';
import { CreateOrderDto } from './dto/create-order.dto';
import { Order, OrderStatus } from './order.entity';
import { OrderChatService } from './order-chat.service';
import {
  branchEmailDesk,
  deskKeyForServiceSlug,
} from './order-routing';

const DEFAULT_BRANCH = 'Yiwu';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly ordersRepo: Repository<Order>,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    private readonly servicesService: ServicesService,
    private readonly offersService: OffersService,
    private readonly notifications: NotificationsService,
    private readonly orderChat: OrderChatService,
  ) {}

  async create(actor: AuthUser, dto: CreateOrderDto) {
    // Validate service exists; ownership never comes from the client body.
    const service = await this.servicesService.requireActiveId(dto.serviceId);

    let offerId: string | null = null;
    let offerTitleEn: string | null = null;
    let offerTitleAr: string | null = null;

    if (dto.offerId) {
      const offer = await this.offersService.requireAvailableForOrder(
        dto.offerId,
      );
      // Hotels/flights offers must match the catalog service slug.
      if (offer.kind !== service.slug) {
        throw new BadRequestException(
          'Offer kind does not match the selected service',
        );
      }
      offerId = offer.id;
      offerTitleEn = offer.titleEn;
      offerTitleAr = offer.titleAr;
    }

    const order = this.ordersRepo.create({
      userId: actor.userId,
      serviceId: service.id,
      status: OrderStatus.Submitted,
      preferredBranch: dto.preferredBranch?.trim() || null,
      subServiceId: dto.subServiceId?.trim() || null,
      subServiceNameEn: dto.subServiceNameEn?.trim() || null,
      subServiceNameAr: dto.subServiceNameAr?.trim() || null,
      formData: dto.formData ?? null,
      notes: dto.notes?.trim() || null,
      offerId,
    });

    const branch = order.preferredBranch ?? DEFAULT_BRANCH;
    order.assignedEmployeeId = await this.resolveAssignee(
      service.slug,
      branch,
    );
    if (order.assignedEmployeeId) {
      order.status = OrderStatus.Assigned;
    }

    const saved = await this.ordersRepo.save(order);
    const conversationId = await this.orderChat.ensureForOrder(saved);
    if (saved.assignedEmployeeId && saved.status === OrderStatus.Assigned) {
      await this.orderChat.postStatusNote(
        conversationId,
        saved.assignedEmployeeId,
        OrderStatus.Assigned,
      );
    }

    await this.notifyOrderStaff({
      orderId: saved.id,
      serviceSlug: service.slug,
      serviceNameEn: service.nameEn,
      serviceNameAr: service.nameAr,
      subServiceNameEn: saved.subServiceNameEn,
      subServiceNameAr: saved.subServiceNameAr,
      customerUserId: actor.userId,
      assignedEmployeeId: saved.assignedEmployeeId,
      hasOffer: Boolean(offerId),
    });

    if (offerId) {
      await this.notifyOffersStaff({
        orderId: saved.id,
        offerId,
        serviceSlug: service.slug,
        offerTitleEn: offerTitleEn ?? 'Offer',
        offerTitleAr: offerTitleAr ?? 'عرض',
        customerUserId: actor.userId,
      });
    }

    return this.toDto(saved, service.slug, conversationId);
  }

  /** Pick branch desk employee for the service category. */
  private async resolveAssignee(
    serviceSlug: string,
    branch: string,
  ): Promise<string | null> {
    const deskKey = deskKeyForServiceSlug(serviceSlug);
    const primaryEmail = branchEmailDesk(branch, deskKey);

    let emp = await this.usersRepo.findOne({
      where: { email: primaryEmail, role: UserRole.Employee },
    });

    if (
      !emp &&
      (serviceSlug === 'hotels' || serviceSlug === 'flights' || serviceSlug === 'vip')
    ) {
      emp = await this.usersRepo.findOne({
        where: {
          branchLabel: branch,
          role: UserRole.Employee,
          offersAccess: true,
        },
      });
    }

    if (!emp) {
      emp = await this.usersRepo.findOne({
        where: { branchLabel: branch, role: UserRole.Employee },
      });
    }

    return emp?.id ?? null;
  }

  /** Notify SuperAdmins + assigned employee when a customer submits a form. */
  private async notifyOrderStaff(opts: {
    orderId: string;
    serviceSlug: string;
    serviceNameEn: string;
    serviceNameAr: string;
    subServiceNameEn: string | null;
    subServiceNameAr: string | null;
    customerUserId: string;
    assignedEmployeeId: string | null;
    hasOffer: boolean;
  }) {
    const superAdmins = await this.usersRepo.find({
      where: { role: UserRole.SuperAdmin },
    });
    const ids = new Set<string>();
    for (const sa of superAdmins) {
      if (sa.id !== opts.customerUserId) ids.add(sa.id);
    }
    if (
      opts.assignedEmployeeId &&
      opts.assignedEmployeeId !== opts.customerUserId
    ) {
      ids.add(opts.assignedEmployeeId);
    }
    if (!ids.size) return;

    const labelEn =
      opts.subServiceNameEn ?? opts.serviceNameEn ?? opts.serviceSlug;
    const labelAr =
      opts.subServiceNameAr ?? opts.serviceNameAr ?? opts.serviceSlug;

    await this.notifications.createForUsers({
      userIds: [...ids],
      kind: NotificationKind.OrderCreated,
      title: 'New service request',
      body: `Customer submitted: ${labelEn}`,
      data: {
        type: 'service_request',
        orderId: opts.orderId,
        serviceSlug: opts.serviceSlug,
        titleEn: labelEn,
        titleAr: labelAr,
        assignedEmployeeId: opts.assignedEmployeeId,
        hasOffer: opts.hasOffer,
      },
    });
  }

  async listMine(actor: AuthUser) {
    const rows = await this.ordersRepo.find({
      where: { userId: actor.userId },
      relations: { service: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((o) => this.toDto(o, o.service?.slug));
  }

  async getMine(actor: AuthUser, orderId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId },
      relations: { service: true },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    if (order.userId !== actor.userId) {
      throw new ForbiddenException('Not your order');
    }
    const conv = await this.orderChat.openForActor(actor, orderId);
    return {
      ...this.toDto(order, order.service?.slug, conv.conversationId),
    };
  }

  async openChat(actor: AuthUser, orderId: string) {
    return this.orderChat.openForActor(actor, orderId);
  }

  /**
   * Notify SuperAdmins + Employees with offersAccess (canManageOffers).
   * Customer who placed the order is never included.
   */
  private async notifyOffersStaff(opts: {
    orderId: string;
    offerId: string;
    serviceSlug: string;
    offerTitleEn: string;
    offerTitleAr: string;
    customerUserId: string;
  }) {
    const staff = await this.usersRepo.find({
      where: [
        { role: UserRole.SuperAdmin },
        { role: UserRole.Employee, offersAccess: true },
      ],
    });
    const ids = staff
      .filter((u) => canManageOffers(u) && u.id !== opts.customerUserId)
      .map((u) => u.id);
    if (!ids.length) return;

    const kindLabel =
      opts.serviceSlug === 'flights' ? 'flight' : 'hotel';
    await this.notifications.createForUsers({
      userIds: ids,
      kind: NotificationKind.OrderCreated,
      title: `New ${kindLabel} offer request`,
      body: `Customer requested: ${opts.offerTitleEn}`,
      data: {
        type: 'offer_request',
        orderId: opts.orderId,
        offerId: opts.offerId,
        serviceSlug: opts.serviceSlug,
        titleAr: opts.offerTitleAr,
        titleEn: opts.offerTitleEn,
      },
    });
  }

  private toDto(
    order: Order,
    serviceSlug?: string,
    conversationId?: string | null,
  ) {
    return {
      id: order.id,
      serviceId: order.serviceId,
      serviceSlug: serviceSlug ?? null,
      subServiceId: order.subServiceId ?? null,
      subServiceNameEn: order.subServiceNameEn ?? null,
      subServiceNameAr: order.subServiceNameAr ?? null,
      formData: order.formData ?? null,
      offerId: order.offerId ?? null,
      status: order.status,
      preferredBranch: order.preferredBranch,
      notes: order.notes,
      assignedEmployeeId: order.assignedEmployeeId ?? null,
      conversationId: conversationId ?? null,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }
}
