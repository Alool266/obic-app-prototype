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
import {
  isChinaMobile,
  normalizeChinaMobile,
  CHINA_PHONE_ONLY_MSG,
} from '../auth/china-phone.util';
import { normalizeRegionCode } from '../auth/china-cohort.util';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ChangeEmailDto } from './dto/change-email.dto';
import { DeleteMeDto } from './dto/delete-me.dto';
import { UpdateMeDto } from './dto/update-me.dto';
import { UpdateAddressesDto } from './dto/update-addresses.dto';
import { decideObicIdChange } from './obic-id.util';
import {
  canSuperAdminSelfDelete,
  LAST_SUPERADMIN_SELF_DELETE_MSG,
} from './superadmin-self-delete';
import { UserAddress } from './user-address.interface';
import { User } from './user.entity';
import { PublicUser, toPublicUser } from './user.mapper';

const BCRYPT_ROUNDS = 12;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
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
        // Profile phone edits that look like China mobile must go through OTP.
        const cn = normalizeChinaMobile(raw);
        if (cn) {
          throw new BadRequestException(
            'Use phone verification OTP to set a China mainland number',
          );
        }
        if (isChinaMobile(raw)) {
          throw new BadRequestException(CHINA_PHONE_ONLY_MSG);
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
    await this.usersRepo.save(user);
    return toPublicUser(user);
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
