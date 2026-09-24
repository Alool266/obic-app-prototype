// Made by Dr Ali
// AES-256-GCM encrypt for TOTP secrets at rest.

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'crypto';

@Injectable()
export class TotpCryptoService {
  private readonly key: Buffer;

  constructor(config: ConfigService) {
    const raw =
      config.get<string>('TOTP_ENCRYPTION_KEY') ??
      config.get<string>('JWT_SECRET') ??
      'obic-dev-totp-key-change-me';
    this.key = createHash('sha256').update(raw).digest();
  }

  encrypt(plain: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key, iv);
    const enc = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return `${iv.toString('base64url')}.${tag.toString('base64url')}.${enc.toString('base64url')}`;
  }

  decrypt(payload: string): string {
    const [ivB64, tagB64, dataB64] = payload.split('.');
    if (!ivB64 || !tagB64 || !dataB64) {
      throw new Error('Invalid encrypted payload');
    }
    const iv = Buffer.from(ivB64, 'base64url');
    const tag = Buffer.from(tagB64, 'base64url');
    const data = Buffer.from(dataB64, 'base64url');
    const decipher = createDecipheriv('aes-256-gcm', this.key, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString(
      'utf8',
    );
  }
}
