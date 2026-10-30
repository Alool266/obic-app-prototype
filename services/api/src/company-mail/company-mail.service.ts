// Made by Dr Ali
// Internal company mail. Customers receive 403. Messages are not sent outside OBIC.

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
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { assertMailBody, assertMailRecipients, normalizeMailSubject } from './company-mail';
import { CompanyMailMessage, CompanyMailRecipient } from './company-mail.entities';
import { SendCompanyMailDto } from './dto/company-mail.dto';

@Injectable()
export class CompanyMailService {
  constructor(
    @InjectRepository(CompanyMailMessage)
    private readonly messages: Repository<CompanyMailMessage>,
    @InjectRepository(CompanyMailRecipient)
    private readonly recipients: Repository<CompanyMailRecipient>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async mine(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const staff = await this.staff();
    const names = new Map(staff.map((person) => [person.id, person.name]));
    const [inboxLinks, sent] = await Promise.all([
      this.recipients.find({
        where: { userId: user.id },
        order: { createdAt: 'DESC' },
        take: 50,
      }),
      this.messages.find({
        where: { senderUserId: user.id },
        order: { createdAt: 'DESC' },
        take: 50,
      }),
    ]);
    const inboxIds = inboxLinks.map((link) => link.messageId);
    const inboxMessages = inboxIds.length
      ? await this.messages.find({ where: { id: In(inboxIds) } })
      : [];
    const sentIds = sent.map((row) => row.id);
    const sentLinks = sentIds.length
      ? await this.recipients.find({ where: { messageId: In(sentIds) } })
      : [];
    const byId = new Map(inboxMessages.map((row) => [row.id, row]));
    const senderIds = inboxMessages.map((row) => row.senderUserId);
    const extra = senderIds.length
      ? await this.users.find({ where: { id: In([...new Set(senderIds)]) } })
      : [];
    for (const person of extra) names.set(person.id, person.name);
    return {
      people: staff
        .filter((person) => person.id !== user.id)
        .map((person) => ({ userId: person.id, name: person.name })),
      inbox: inboxLinks.flatMap((link) => {
        const row = byId.get(link.messageId);
        if (!row) return [];
        return [
          {
            id: row.id,
            subject: row.subject,
            body: row.body,
            senderName: names.get(row.senderUserId) ?? null,
            createdAt: row.createdAt,
            read: link.readAt != null,
          },
        ];
      }),
      sent: sent.map((row) => ({
        id: row.id,
        subject: row.subject,
        body: row.body,
        recipientNames: sentLinks
          .filter((link) => link.messageId === row.id)
          .map((link) => names.get(link.userId) ?? null)
          .filter((name): name is string => name != null),
        createdAt: row.createdAt,
      })),
    };
  }

  async send(actor: AuthUser, dto: SendCompanyMailDto) {
    const user = await this.requireStaff(actor);
    const saved = await this.deliver(user, dto);
    await this.audit(user.id, saved.message.id, saved.recipientCount);
    return { id: saved.message.id, subject: saved.message.subject, createdAt: saved.message.createdAt };
  }

  async markRead(actor: AuthUser, id: string) {
    const user = await this.requireStaff(actor);
    const link = await this.recipients.findOne({ where: { messageId: id, userId: user.id } });
    if (!link) throw new NotFoundException('This message was not found');
    if (!link.readAt) {
      link.readAt = new Date();
      await this.recipients.save(link);
    }
    return { id, read: true };
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const rows = await this.messages.find({ order: { createdAt: 'DESC' }, take: 80 });
    const ids = rows.map((row) => row.id);
    const links = ids.length ? await this.recipients.find({ where: { messageId: In(ids) } }) : [];
    const userIds = [
      ...rows.map((row) => row.senderUserId),
      ...links.map((link) => link.userId),
    ];
    const names = await this.namesFor(userIds);
    return {
      people: (await this.staff()).map((person) => ({ userId: person.id, name: person.name })),
      rows: rows.map((row) => ({
        id: row.id,
        subject: row.subject,
        body: row.body,
        senderName: names.get(row.senderUserId) ?? null,
        recipientNames: links
          .filter((link) => link.messageId === row.id)
          .map((link) => names.get(link.userId) ?? null)
          .filter((name): name is string => name != null),
        createdAt: row.createdAt,
      })),
    };
  }

  async sendAdmin(actor: AuthUser, dto: SendCompanyMailDto) {
    const user = await this.requireSuperAdmin(actor);
    const saved = await this.deliver(user, dto);
    await this.audit(user.id, saved.message.id, saved.recipientCount);
    return { id: saved.message.id, subject: saved.message.subject, createdAt: saved.message.createdAt };
  }

  private async deliver(user: User, dto: SendCompanyMailDto) {
    const staff = await this.staff();
    const allowed = new Set(staff.map((person) => person.id));
    let subject: string;
    let body: string;
    let userIds: string[];
    try {
      subject = normalizeMailSubject(dto.subject);
      body = assertMailBody(dto.body);
      userIds = assertMailRecipients(dto.userIds, user.id, allowed);
    } catch (error) {
      throw this.statusError(error);
    }
    return this.messages.manager.transaction(async (manager) => {
      const messages = manager.getRepository(CompanyMailMessage);
      const boxes = manager.getRepository(CompanyMailRecipient);
      const saved = await messages.save(
        messages.create({
          senderUserId: user.id,
          subject,
          body,
        }),
      );
      await boxes.save(
        userIds.map((userId) => boxes.create({ messageId: saved.id, userId, readAt: null })),
      );
      return { message: saved, recipientCount: userIds.length };
    });
  }

  private async staff(): Promise<User[]> {
    return this.users.find({
      where: [
        { role: UserRole.Employee, deletedAt: IsNull() },
        { role: UserRole.SuperAdmin, deletedAt: IsNull() },
      ],
      order: { name: 'ASC' },
    });
  }

  private async namesFor(ids: string[]): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const people = await this.users.find({ where: { id: In(unique) } });
    return new Map(people.map((person) => [person.id, person.name]));
  }

  private statusError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'MAIL_SUBJECT':
        return new BadRequestException('Enter a subject up to 80 characters');
      case 'MAIL_BODY':
        return new BadRequestException('Enter a message up to 2000 characters');
      case 'MAIL_RECIPIENT':
        return new BadRequestException('Choose a staff member');
      case 'MAIL_COUNT':
        return new BadRequestException('Choose at most 12 people');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the message');
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

  private async audit(actorId: string, resourceId: string, recipientCount: number) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action: 'company_mail_send',
        resourceType: 'company_mail',
        resourceId,
        meta: { recipientCount },
      }),
    );
  }
}
