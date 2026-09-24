// Made by Dr Ali
// Users service — profile reads/writes always scoped to the authenticated principal.

import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Not, Repository } from 'typeorm';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UpdateMeDto } from './dto/update-me.dto';
import { UpdateAddressesDto } from './dto/update-addresses.dto';
import { UserAddress } from './user-address.interface';
import { User } from './user.entity';
import { PublicUser, toPublicUser } from './user.mapper';

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
      const phone = dto.phone.trim();
      if (phone.length === 0) {
        user.phone = null;
      } else {
        const taken = await this.usersRepo.findOne({
          where: { phone, id: Not(user.id) },
        });
        if (taken) {
          throw new ConflictException('Phone already in use');
        }
        user.phone = phone;
      }
    }

    await this.usersRepo.save(user);
    return toPublicUser(user);
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
