// Made by Dr Ali
// Server Moments notify prefs — defaults when no row; friendship-gated mutes.

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { FriendsService } from '../friends/friends.service';
import { User } from '../users/user.entity';
import { UpdateMomentNotifyPrefsDto } from './dto/moment-notify-prefs.dto';
import { MomentFriendMute } from './moment-friend-mute.entity';
import {
  filterMomentNotifyRecipients,
  shouldReceiveMomentNotify,
} from './moment-notify-filter';
import { MomentNotifyPrefs } from './moment-notify-prefs.entity';

export type MomentNotifyPrefsDto = {
  notifyEnabled: boolean;
  muteUpdates: boolean;
  mutedFriendIds: string[];
};

@Injectable()
export class MomentNotifyPrefsService {
  constructor(
    @InjectRepository(MomentNotifyPrefs)
    private readonly prefs: Repository<MomentNotifyPrefs>,
    @InjectRepository(MomentFriendMute)
    private readonly mutes: Repository<MomentFriendMute>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly friends: FriendsService,
  ) {}

  async getMine(actor: AuthUser): Promise<MomentNotifyPrefsDto> {
    const row = await this.prefs.findOne({ where: { userId: actor.userId } });
    const muted = await this.mutes.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
    });
    return {
      notifyEnabled: row?.notifyEnabled ?? true,
      muteUpdates: row?.muteUpdates ?? false,
      mutedFriendIds: muted.map((m) => m.mutedFriendId),
    };
  }

  async updateMine(
    actor: AuthUser,
    dto: UpdateMomentNotifyPrefsDto,
  ): Promise<MomentNotifyPrefsDto> {
    let row = await this.prefs.findOne({ where: { userId: actor.userId } });
    if (!row) {
      row = this.prefs.create({
        userId: actor.userId,
        notifyEnabled: true,
        muteUpdates: false,
      });
    }

    if (dto.notifyEnabled !== undefined) {
      row.notifyEnabled = dto.notifyEnabled;
      if (dto.notifyEnabled) {
        row.muteUpdates = false;
      }
    }
    if (dto.muteUpdates !== undefined) {
      row.muteUpdates = dto.muteUpdates;
      if (dto.muteUpdates) {
        row.notifyEnabled = false;
      } else if (dto.notifyEnabled === undefined) {
        row.notifyEnabled = true;
      }
    }

    await this.prefs.save(row);

    if (dto.mutedFriendIds !== undefined) {
      await this.replaceMutes(actor.userId, dto.mutedFriendIds);
    }

    return this.getMine(actor);
  }

  async muteFriend(actor: AuthUser, friendId: string): Promise<MomentNotifyPrefsDto> {
    if (friendId === actor.userId) {
      throw new BadRequestException('Cannot mute yourself');
    }
    const ok = await this.friends.areFriends(actor.userId, friendId);
    if (!ok) {
      throw new BadRequestException('Can only mute Moments from friends');
    }
    const friend = await this.users.findOne({ where: { id: friendId } });
    if (!friend) throw new NotFoundException('User not found');

    const existing = await this.mutes.findOne({
      where: { userId: actor.userId, mutedFriendId: friendId },
    });
    if (!existing) {
      await this.mutes.save(
        this.mutes.create({
          userId: actor.userId,
          mutedFriendId: friendId,
        }),
      );
    }
    return this.getMine(actor);
  }

  async unmuteFriend(
    actor: AuthUser,
    friendId: string,
  ): Promise<MomentNotifyPrefsDto> {
    await this.mutes.delete({
      userId: actor.userId,
      mutedFriendId: friendId,
    });
    return this.getMine(actor);
  }

  /** True when this recipient should receive Moments fan-out from author. */
  async shouldNotifyRecipient(
    recipientId: string,
    authorId: string,
  ): Promise<boolean> {
    const row = await this.prefs.findOne({ where: { userId: recipientId } });
    const muted = await this.mutes.findOne({
      where: { userId: recipientId, mutedFriendId: authorId },
    });
    return shouldReceiveMomentNotify(
      recipientId,
      authorId,
      row
        ? {
            userId: row.userId,
            notifyEnabled: row.notifyEnabled,
            muteUpdates: row.muteUpdates,
          }
        : null,
      !!muted,
    );
  }

  /**
   * Filter user ids that still want Moments notifications from [authorId].
   */
  async filterNotifyRecipients(
    candidateIds: string[],
    authorId: string,
  ): Promise<string[]> {
    const unique = [...new Set(candidateIds)].filter(
      (id) => id && id !== authorId,
    );
    if (!unique.length) return [];

    const prefsRows = await this.prefs.find({
      where: { userId: In(unique) },
    });
    const muted = await this.mutes.find({
      where: { userId: In(unique), mutedFriendId: authorId },
    });

    return filterMomentNotifyRecipients(
      unique,
      authorId,
      prefsRows.map((p) => ({
        userId: p.userId,
        notifyEnabled: p.notifyEnabled,
        muteUpdates: p.muteUpdates,
      })),
      muted.map((m) => ({
        userId: m.userId,
        mutedFriendId: m.mutedFriendId,
      })),
    );
  }

  private async replaceMutes(
    userId: string,
    friendIds: string[],
  ): Promise<void> {
    const unique = [...new Set(friendIds)].filter((id) => id && id !== userId);
    for (const id of unique) {
      const ok = await this.friends.areFriends(userId, id);
      if (!ok) {
        throw new BadRequestException(
          `Can only mute Moments from friends (${id})`,
        );
      }
    }
    await this.mutes.delete({ userId });
    if (!unique.length) return;
    await this.mutes.save(
      unique.map((mutedFriendId) =>
        this.mutes.create({ userId, mutedFriendId }),
      ),
    );
  }
}
