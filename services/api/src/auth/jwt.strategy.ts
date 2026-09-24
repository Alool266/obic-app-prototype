// Made by Dr Ali
// Passport JWT strategy — validates Bearer access tokens.

import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ObicJwtPayload } from './jwt-payload.interface';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(config: ConfigService) {
    const secret = config.get<string>('JWT_SECRET');
    if (!secret) {
      // Fail loud in boot rather than signing with a silent default.
      throw new Error(
        'JWT_SECRET is required (set in .env — never ship in the app)',
      );
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  validate(payload: ObicJwtPayload): AuthUser {
    if (!payload?.sub || !payload?.sid) {
      throw new UnauthorizedException('Invalid token');
    }
    return new AuthUser(payload.sub, payload.sid, payload.role);
  }
}
