// Made by Dr Ali
// In-app notifications — create fan-out + list/mark-read for the JWT subject.

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RealtimeService } from '../realtime/realtime.service';
import {
  Notification,
  NotificationKind,
} from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly repo: Repository<Notification>,
    private readonly realtime: RealtimeService,
  ) {}

  async listMine(actor: AuthUser, limit = 50) {
    const rows = await this.repo.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
      take: Math.min(limit, 100),
    });
    return rows.map((n) => this.toDto(n));
  }

  async unreadCount(actor: AuthUser) {
    const unreadCount = await this.repo.count({
      where: { userId: actor.userId, readAt: IsNull() },
    });
    return { unreadCount };
  }

  async markRead(actor: AuthUser, id: string) {
    const row = await this.repo.findOne({ where: { id } });
    if (!row || row.userId !== actor.userId) {
      throw new NotFoundException('Notification not found');
    }
    if (!row.readAt) {
      row.readAt = new Date();
      await this.repo.save(row);
    }
    return this.toDto(row);
  }

  async markAllRead(actor: AuthUser) {
    await this.repo.update(
      { userId: actor.userId, readAt: IsNull() },
      { readAt: new Date() },
    );
    return { ok: true };
  }

  /** Fan-out helper used by Moments / Friends — never exposed as a public write API. */
  async createForUsers(options: {
    userIds: string[];
    kind: NotificationKind;
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }) {
    const unique = [...new Set(options.userIds)].filter(Boolean);
    if (!unique.length) return;
    const rows = unique.map((userId) =>
      this.repo.create({
        userId,
        kind: options.kind,
        title: options.title,
        body: options.body,
        data: options.data ?? null,
      }),
    );
    await this.repo.save(rows);
    for (const row of rows) {
      this.realtime.publishNotification({
        userIds: [row.userId],
        notification: this.toDto(row),
      });
    }
  }

  async createForAllUsersExcept(
    exceptUserId: string,
    options: {
      kind: NotificationKind;
      title: string;
      body: string;
      data?: Record<string, unknown>;
    },
  ) {
    // Bulk insert via raw SQL for notify-all staff moments.
    await this.repo.query(
      `
      INSERT INTO notifications (user_id, kind, title, body, data)
      SELECT u.id, $1, $2, $3, $4::jsonb
      FROM users u
      WHERE u.id <> $5
      `,
      [
        options.kind,
        options.title,
        options.body,
        JSON.stringify(options.data ?? null),
        exceptUserId,
      ],
    );
  }

  private toDto(n: Notification) {
    return {
      id: n.id,
      kind: n.kind,
      type: n.kind,
      title: n.title,
      body: n.body,
      data: n.data,
      readAt: n.readAt,
      createdAt: n.createdAt,
    };
  }
}
