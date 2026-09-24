// Made by Dr Ali
// Block /v1/admin/* when ADMIN_IP_ALLOWLIST is set and client IP is outside it.

import { Injectable, NestMiddleware } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NextFunction, Request, Response } from 'express';
import {
  clientIpFromRequest,
  ipMatchesAllowlist,
  parseAdminIpAllowlist,
} from '../admin-security';

@Injectable()
export class AdminIpAllowlistMiddleware implements NestMiddleware {
  constructor(private readonly config: ConfigService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const allowlist = parseAdminIpAllowlist(this.config);
    if (allowlist.length === 0) {
      next();
      return;
    }
    const trustProxy =
      this.config.get<string>('TRUST_PROXY')?.trim().toLowerCase() === 'true' ||
      this.config.get<string>('NODE_ENV') === 'production';
    const ip = clientIpFromRequest(req, trustProxy);
    if (!ipMatchesAllowlist(ip, allowlist)) {
      res.status(403).json({
        message: 'Admin access denied from this network',
        code: 'ADMIN_IP_DENIED',
      });
      return;
    }
    next();
  }
}
