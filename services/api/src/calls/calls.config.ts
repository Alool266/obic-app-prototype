// Made by Dr Ali
// Phase 5 Agora — App ID + certificate server-only; never ship certificate to Flutter.

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export const AGORA_CONSOLE_URL = 'https://console.agora.io/';

@Injectable()
export class CallsConfig {
  constructor(private readonly config: ConfigService) {}

  get appId(): string {
    return (this.config.get<string>('AGORA_APP_ID') ?? '').trim();
  }

  get appCertificate(): string {
    return (this.config.get<string>('AGORA_APP_CERTIFICATE') ?? '').trim();
  }

  get configured(): boolean {
    return this.appId.length > 0 && this.appCertificate.length > 0;
  }

  /** Token TTL seconds (default 1h; Agora free-tier friendly). */
  get tokenTtlSeconds(): number {
    const n = Number(
      this.config.get<string>('AGORA_TOKEN_TTL_SECONDS') ?? '3600',
    );
    return Number.isFinite(n) && n >= 60 ? Math.min(n, 86_400) : 3600;
  }
}
