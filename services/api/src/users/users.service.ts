// Made by Dr Ali
// Users service — profile reads/writes always scoped to the authenticated principal.

import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { IsNull, Not, Repository } from 'typeorm';
import { normalizeSmsMobile } from '../auth/sms-phone.util';
import { normalizeRegionCode } from '../auth/china-cohort.util';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ChangeEmailDto } from './dto/change-email.dto';
import { DeleteMeDto } from './dto/delete-me.dto';
import { UpdateMeDto } from './dto/update-me.dto';
import { UpdateAddressesDto } from './dto/update-addresses.dto';
import { UpdateHomeLayoutDto } from './dto/update-home-layout.dto';
import { decideObicIdChange } from './obic-id.util';
import {
  canSuperAdminSelfDelete,
  LAST_SUPERADMIN_SELF_DELETE_MSG,
} from './superadmin-self-delete';
import { UserAddress } from './user-address.interface';
import { User } from './user.entity';
import { UserHomeLayout } from './user-home-layout.entity';
import { PublicUser, toPublicUser } from './user.mapper';

const BCRYPT_ROUNDS = 12;

export type MiniAppsLayoutPayload = {
  order: string[];
  favorites: string[];
  hidden: string[];
};

export type HomeLayoutPayload = {
  order: string[];
  favorites: string[];
  hidden: string[];
  miniApps: MiniAppsLayoutPayload;
};

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    @InjectRepository(UserHomeLayout)
    private readonly homeLayoutRepo: Repository<UserHomeLayout>,
  ) {}

  /** "Me" profile — never accept a client-supplied userId for this path. */
  async findMe(actor: AuthUser): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return toPublicUser(user);
  }

  async updateAvatar(actor: AuthUser, avatarUrl: string): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.avatarUrl = avatarUrl.trim();
    await this.usersRepo.save(user);
    return toPublicUser(user);
  }

  /**
   * Self-service name/phone update.
   * Security: JWT subject only; cannot change role, email, or password here.
   */
  async updateMe(actor: AuthUser, dto: UpdateMeDto): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (dto.name !== undefined) {
      const name = dto.name.trim();
      if (name.length < 2) {
        throw new BadRequestException('Name too short');
      }
      user.name = name;
    }

    if (dto.phone !== undefined) {
      const raw = dto.phone.trim();
      if (raw.length === 0) {
        user.phone = null;
        user.phoneVerifiedAt = null;
      } else {
        // China, Saudi, and Yemen mobiles must go through the OTP.
        const sms = normalizeSmsMobile(raw);
        if (sms) {
          throw new BadRequestException(
            'Use phone verification OTP to set this mobile number',
          );
        }
        const phone = raw;
        const taken = await this.usersRepo.findOne({
          where: { phone, id: Not(user.id) },
        });
        if (taken) {
          throw new ConflictException('Phone already in use');
        }
        user.phone = phone;
        user.phoneVerifiedAt = null;
      }
    }

    if (dto.city !== undefined) {
      const city = dto.city.trim();
      user.city = city.length === 0 ? null : city;
    }

    if (dto.country !== undefined) {
      const raw = dto.country.trim();
      if (raw.length === 0) {
        user.country = null;
      } else {
        // Prefer ISO code when recognizable; otherwise store trimmed label.
        user.country = normalizeRegionCode(raw) ?? raw.slice(0, 120);
      }
    }

    if (dto.gender !== undefined) {
      const raw = dto.gender.trim().toLowerCase();
      if (raw.length === 0) {
        user.gender = null;
      } else if (raw === 'male' || raw === 'female' || raw === 'other') {
        user.gender = raw;
      } else {
        throw new BadRequestException(
          'Gender must be male, female, other, or empty',
        );
      }
    }

    if (dto.whatsUp !== undefined) {
      const raw = dto.whatsUp.trim();
      user.whatsUp = raw.length === 0 ? null : raw.slice(0, 120);
    }

    if (dto.obicId !== undefined) {
      const decision = decideObicIdChange({
        current: user.obicId,
        nextRaw: dto.obicId,
        changedAt: user.obicIdChangedAt,
      });
      if (!decision.ok) {
        if (decision.reason === 'unchanged') {
          // No-op — leave row as-is.
        } else if (decision.reason === 'invalid') {
          throw new BadRequestException(
            'OBIC ID must be 6–20 chars, start with a letter, and use letters, digits, or _',
          );
        } else {
          const when = decision.nextAt
            ? decision.nextAt.toISOString().slice(0, 10)
            : 'later';
          throw new BadRequestException(
            `OBIC ID can only be changed once every 365 days. Next change available on ${when}.`,
          );
        }
      } else {
        const taken = await this.usersRepo.findOne({
          where: { obicId: decision.normalized, id: Not(user.id) },
        });
        if (taken) {
          throw new ConflictException('OBIC ID already in use');
        }
        user.obicId = decision.normalized;
        user.obicIdChangedAt = new Date();
      }
    }

    await this.usersRepo.save(user);
    return toPublicUser(user);
  }

  /**
   * Change own password — requires current password.
   * Security: JWT subject only; never log the new password.
   */
  async changePassword(
    actor: AuthUser,
    dto: ChangePasswordDto,
  ): Promise<{ ok: true }> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const ok = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    const next = dto.newPassword.trim();
    if (next.length < 8) {
      throw new BadRequestException('New password too short');
    }
    user.passwordHash = await bcrypt.hash(next, BCRYPT_ROUNDS);
    await this.usersRepo.save(user);
    return { ok: true };
  }

  /**
   * Change email — requires current password.
   * New email must be unique; old email is freed for re-registration.
   */
  async changeEmail(
    actor: AuthUser,
    dto: ChangeEmailDto,
  ): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (user.deletedAt) {
      throw new UnauthorizedException('Account deactivated');
    }
    const ok = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    const email = dto.email.trim().toLowerCase();
    if (!email || !email.includes('@')) {
      throw new BadRequestException('Invalid email');
    }
    if (user.email && user.email.toLowerCase() === email) {
      return toPublicUser(user);
    }
    const taken = await this.usersRepo.findOne({
      where: { email, id: Not(user.id) },
    });
    if (taken) {
      throw new ConflictException('Email already in use');
    }
    user.email = email;
    await this.usersRepo.save(user);
    return toPublicUser(user);
  }

  async updateMomentsCover(
    actor: AuthUser,
    coverUrl: string,
    focusY?: number,
  ): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (user.deletedAt) {
      throw new UnauthorizedException('Account deactivated');
    }
    const url = coverUrl.trim();
    user.momentsCoverUrl = url.length === 0 ? null : url.slice(0, 1024);
    if (typeof focusY === 'number' && Number.isFinite(focusY)) {
      user.momentsCoverFocusY = Math.min(1, Math.max(-1, focusY));
    } else if (url.length === 0) {
      user.momentsCoverFocusY = 0;
    }
    await this.usersRepo.save(user);
    return toPublicUser(user);
  }

  /**
   * Public Moments profile header (name / avatar / cover) — no email/phone.
   * Used when opening a friend’s Moments album.
   */
  async momentsProfile(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('User not found');
    }
    return {
      id: user.id,
      name: user.name,
      role: user.role,
      avatarUrl: user.avatarUrl ?? null,
      whatsUp: user.whatsUp ?? null,
      city: user.city ?? null,
      country: user.country ?? null,
      momentsCoverUrl: user.momentsCoverUrl ?? null,
      momentsCoverFocusY:
        typeof user.momentsCoverFocusY === 'number'
          ? user.momentsCoverFocusY
          : 0,
    };
  }

  /**
   * Soft-delete / deactivate own account (WeChat-style).
   * Requires current password. Password hash kept so admin restore → same login.
   * SuperAdmin: allowed only when another active SuperAdmin remains.
   */
  async deleteMe(actor: AuthUser, dto: DeleteMeDto): Promise<{ ok: true }> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (user.deletedAt) {
      throw new BadRequestException('Account already deactivated');
    }
    const ok = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    if (user.role === UserRole.SuperAdmin) {
      const otherSas = await this.usersRepo.count({
        where: {
          role: UserRole.SuperAdmin,
          id: Not(user.id),
          deletedAt: IsNull(),
        },
      });
      if (!canSuperAdminSelfDelete(otherSas)) {
        throw new BadRequestException(LAST_SUPERADMIN_SELF_DELETE_MSG);
      }
    }
    user.deletedAt = new Date();
    await this.usersRepo.save(user);
    return { ok: true };
  }

  /** Home icon layout — empty arrays mean catalog defaults on the client. */
  async getHomeLayout(actor: AuthUser): Promise<HomeLayoutPayload> {
    const row = await this.homeLayoutRepo.findOne({
      where: { userId: actor.userId },
    });
    if (!row) {
      return {
        order: [],
        favorites: [],
        hidden: [],
        miniApps: { order: [], favorites: [], hidden: [] },
      };
    }
    return {
      order: this.normalizeSlugList(row.orderSlugs),
      favorites: this.normalizeSlugList(row.favorites),
      hidden: this.normalizeSlugList(row.hidden),
      miniApps: {
        order: this.normalizeSlugList(row.miniOrder),
        favorites: this.normalizeSlugList(row.miniFavorites),
        hidden: this.normalizeSlugList(row.miniHidden),
      },
    };
  }

  async putHomeLayout(
    actor: AuthUser,
    dto: UpdateHomeLayoutDto,
  ): Promise<HomeLayoutPayload> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const order = this.normalizeSlugList(dto.order);
    const hidden = this.normalizeSlugList(dto.hidden);
    const hiddenSet = new Set(hidden);
    const favorites = this.normalizeSlugList(dto.favorites).filter(
      (slug) => !hiddenSet.has(slug),
    );

    let row = await this.homeLayoutRepo.findOne({
      where: { userId: actor.userId },
    });
    if (!row) {
      row = this.homeLayoutRepo.create({
        userId: actor.userId,
        orderSlugs: order,
        favorites,
        hidden,
        miniOrder: [],
        miniFavorites: [],
        miniHidden: [],
      });
    } else {
      row.orderSlugs = order;
      row.favorites = favorites;
      row.hidden = hidden;
    }

    if (dto.miniApps) {
      const miniHidden = this.normalizeSlugList(dto.miniApps.hidden);
      const miniHiddenSet = new Set(miniHidden);
      row.miniOrder = this.normalizeSlugList(dto.miniApps.order);
      row.miniFavorites = this.normalizeSlugList(dto.miniApps.favorites).filter(
        (id) => !miniHiddenSet.has(id),
      );
      row.miniHidden = miniHidden;
    }

    await this.homeLayoutRepo.save(row);
    return {
      order,
      favorites,
      hidden,
      miniApps: {
        order: this.normalizeSlugList(row.miniOrder),
        favorites: this.normalizeSlugList(row.miniFavorites),
        hidden: this.normalizeSlugList(row.miniHidden),
      },
    };
  }

  private normalizeSlugList(raw: unknown): string[] {
    if (!Array.isArray(raw)) return [];
    const seen = new Set<string>();
    const out: string[] = [];
    for (const item of raw) {
      if (typeof item !== 'string') continue;
      const slug = item.trim().toLowerCase();
      if (!slug || seen.has(slug)) continue;
      if (!/^[a-z0-9][a-z0-9_-]{0,62}$/.test(slug)) continue;
      seen.add(slug);
      out.push(slug);
      if (out.length >= 64) break;
    }
    return out;
  }

  /** Replace saved delivery addresses (max 20). */
  async updateAddresses(
    actor: AuthUser,
    dto: UpdateAddressesDto,
  ): Promise<PublicUser> {
    const user = await this.usersRepo.findOne({ where: { id: actor.userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const normalized = this.normalizeAddresses(dto.addresses);
    user.addresses = normalized;
    await this.usersRepo.save(user);
    return toPublicUser(user);
  }

  private normalizeAddresses(raw: UpdateAddressesDto['addresses']): UserAddress[] {
    const seen = new Set<string>();
    const out: UserAddress[] = [];

    for (const row of raw) {
      const id = row.id.trim();
      if (!id || seen.has(id)) continue;
      seen.add(id);

      const label = row.label.trim();
      const line1 = row.line1.trim();
      const city = row.city.trim();
      if (label.length < 1 || line1.length < 2 || city.length < 2) {
        throw new BadRequestException('Each address needs label, street, and city');
      }

      out.push({
        id,
        label,
        line1,
        line2: row.line2?.trim() || undefined,
        city,
        district: row.district?.trim() || undefined,
        notes: row.notes?.trim() || undefined,
        isDefault: row.isDefault === true,
      });
    }

    if (out.length === 0) {
      return [];
    }

    const defaults = out.filter((a) => a.isDefault);
    if (defaults.length === 0) {
      out[0] = { ...out[0], isDefault: true };
    } else if (defaults.length > 1) {
      let picked = false;
      for (let i = 0; i < out.length; i += 1) {
        if (out[i].isDefault && !picked) {
          picked = true;
        } else {
          out[i] = { ...out[i], isDefault: false };
        }
      }
    }

    return out;
  }
}
