// Made by Dr Ali
// TOTP enroll / verify — RFC 6238 via otplib.

import { Injectable } from '@nestjs/common';
import { authenticator } from 'otplib';

@Injectable()
export class TotpService {
  private readonly issuer = 'OBIC Admin';

  generateSecret(): string {
    return authenticator.generateSecret();
  }

  keyUri(accountLabel: string, secret: string): string {
    return authenticator.keyuri(accountLabel, this.issuer, secret);
  }

  verify(code: string, secret: string): boolean {
    const token = code.replace(/\s/g, '');
    if (!/^\d{6}$/.test(token)) return false;
    try {
      return authenticator.verify({ token, secret });
    } catch {
      return false;
    }
  }
}
