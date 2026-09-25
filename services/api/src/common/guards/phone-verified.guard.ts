// Made by Dr Ali
// Soft-block chat/orders until China cohort completes mainland phone OTP.

import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  needsPhoneVerification,
  PHONE_VERIFICATION_REQUIRED_MSG,
} from '../../auth/china-cohort.util';
import { AuthUser } from '../interfaces/auth-user.interface';
import { User } from '../../users/user.entity';

@Injectable()
export class PhoneVerifiedGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    const actor = req.user;
    if (!actor?.userId) return true;

    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (!user) return true;
    if (!needsPhoneVerification(user)) return true;

    throw new ForbiddenException(PHONE_VERIFICATION_REQUIRED_MSG);
  }
}
