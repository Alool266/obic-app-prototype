// Made by Dr Ali
// Deliver a notification through Apple Push or Firebase.
// Keys stay in the server environment. If they are missing, this is a no-op.

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { createSign } from 'crypto';
import { Buffer } from 'buffer';
import { readFileSync } from 'fs';
import { connect } from 'node:http2';
import { Repository } from 'typeorm';
import { PushDevice } from './push-device.entity';

@Injectable()
export class PushService {
  private readonly log = new Logger(PushService.name);
  private apnsJwt: { token: string; at: number } | null = null;
  private fcmJwt: { token: string; at: number } | null = null;

  constructor(
    @InjectRepository(PushDevice)
    private readonly devices: Repository<PushDevice>,
    private readonly config: ConfigService,
  ) {}

  async register(userId: string, platform: string, token: string) {
    const clean = token.trim();
    if (!clean) return { ok: false };
    const kind =
      platform === 'android' || platform === 'android_cn'
        ? platform
        : platform === 'ios_voip'
          ? 'ios_voip'
          : 'ios';
    const existing = await this.devices.findOne({ where: { token: clean } });
    if (existing) {
      existing.userId = userId;
      existing.platform = kind;
      await this.devices.save(existing);
      return { ok: true };
    }
    await this.devices.save(
      this.devices.create({ userId, platform: kind, token: clean }),
    );
    return { ok: true };
  }

  async sendToUsers(options: {
    userIds: string[];
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }) {
    const ids = [...new Set(options.userIds.filter(Boolean))];
    if (!ids.length) return;
    const rows = await this.devices
      .createQueryBuilder('d')
      .where('d.user_id IN (:...ids)', { ids })
      .getMany();
    const kind = options.data?.kind;
    const byUser = new Map<string, PushDevice[]>();
    for (const row of rows) {
      const list = byUser.get(row.userId) ?? [];
      list.push(row);
      byUser.set(row.userId, list);
    }
    const jobs: Promise<void>[] = [];
    for (const devices of byUser.values()) {
      const android = devices.filter(
        (row) => row.platform === 'android' || row.platform === 'android_cn',
      );
      const voip = devices.filter((row) => row.platform === 'ios_voip');
      const ios = devices.filter((row) => row.platform === 'ios');
      if (kind === 'call') {
        for (const row of android) jobs.push(this.safe(row, options));
        if (voip.length) {
          for (const row of voip) jobs.push(this.safe(row, options));
        } else {
          for (const row of ios) jobs.push(this.safe(row, options));
        }
        continue;
      }
      if (kind === 'call_ended') {
        for (const row of [...android, ...ios]) jobs.push(this.safe(row, options));
        continue;
      }
      for (const row of [...android, ...ios]) jobs.push(this.safe(row, options));
    }
    await Promise.all(jobs);
  }

  private safe(
    row: PushDevice,
    options: { title: string; body: string; data?: Record<string, unknown> },
  ) {
    return this.sendOne(row, options.title, options.body, options.data).catch(
      (error: unknown) => {
        this.log.warn(
          `push failed ${row.platform}: ${error instanceof Error ? error.message : 'error'}`,
        );
      },
    );
  }

  private async sendOne(
    row: PushDevice,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ) {
    if (row.platform === 'android' || row.platform === 'android_cn') {
      await this.sendFcm(row.token, title, body, data, row.platform === 'android_cn');
      return;
    }
    await this.sendApns(row.token, title, body, data, row.platform === 'ios_voip');
  }

  private async sendApns(
    token: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
    voip = false,
  ) {
    const jwt = this.appleJwt();
    const topic = this.config.get<string>('APNS_BUNDLE_ID')?.trim();
    if (!jwt || !topic) return;
    const host =
      this.config.get<string>('APNS_ENV') === 'production'
        ? 'https://api.push.apple.com'
        : 'https://api.sandbox.push.apple.com';
    const ended = data?.kind === 'call_ended';
    const call = data?.kind === 'call';
    const payload = voip
      ? this.stringData({ ...data, title, body })
      : {
          aps: ended
            ? { 'content-available': 1 }
            : {
                alert: { title, body },
                sound: 'default',
                'mutable-content': 1,
                ...(call
                  ? {
                      'content-available': 1,
                      'interruption-level': 'time-sensitive',
                    }
                  : {}),
              },
          ...this.stringData({ ...data, title, body }),
        };
    const pushType = voip ? 'voip' : ended ? 'background' : 'alert';
    await this.postApns({
      host,
      path: `/3/device/${token}`,
      jwt,
      topic: voip ? `${topic}.voip` : topic,
      pushType,
      priority: pushType === 'background' ? '5' : '10',
      body: JSON.stringify(payload),
    });
  }

  /** Apple only accepts HTTP/2. Node fetch stays on HTTP/1.1 and the send dies. */
  private postApns(options: {
    host: string;
    path: string;
    jwt: string;
    topic: string;
    pushType: string;
    priority: string;
    body: string;
  }): Promise<void> {
    return new Promise((resolve, reject) => {
      let settled = false;
      const client = connect(options.host);
      const finish = (error?: Error) => {
        if (settled) return;
        settled = true;
        client.close();
        if (error) reject(error);
        else resolve();
      };
      client.on('error', (error) => finish(error));
      const req = client.request({
        ':method': 'POST',
        ':path': options.path,
        authorization: `bearer ${options.jwt}`,
        'apns-topic': options.topic,
        'apns-push-type': options.pushType,
        'apns-priority': options.priority,
        'content-type': 'application/json',
      });
      const chunks: Buffer[] = [];
      req.on('response', (headers) => {
        const status = Number(headers[':status'] ?? 0);
        req.on('data', (chunk: Buffer | string) => {
          chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
        });
        req.on('end', () => {
          if (status === 200) {
            finish();
            return;
          }
          let reason = '';
          try {
            const parsed = JSON.parse(Buffer.concat(chunks).toString('utf8')) as {
              reason?: string;
            };
            reason = parsed.reason ?? '';
          } catch {
            reason = '';
          }
          finish(new Error(`apns ${status}${reason ? ` ${reason}` : ''}`));
        });
      });
      req.on('error', (error) => finish(error));
      req.setTimeout(10_000, () => {
        req.close();
        finish(new Error('apns timeout'));
      });
      req.end(options.body);
    });
  }

  private async sendFcm(
    token: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
    china = false,
  ) {
    const access = await this.googleAccessToken();
    const project = this.config.get<string>('FCM_PROJECT_ID')?.trim();
    if (!access || !project) return;
    const kind = data?.kind;
    // Calls stay data-only so the phone can draw Accept / Decline.
    // Messages use a visible notification so a closed app still banners.
    // China phones draw the banner themselves. A Google notification payload
    // would show a second alert on the ones that still have Play Services.
    const dataOnly = china || kind === 'call' || kind === 'call_ended';
    const avatar =
      typeof data?.avatarUrl === 'string' && data.avatarUrl.startsWith('http')
        ? data.avatarUrl
        : '';
    await fetch(
      `https://fcm.googleapis.com/v1/projects/${project}/messages:send`,
      {
        method: 'POST',
        headers: {
          authorization: `Bearer ${access}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          message: dataOnly
            ? {
                token,
                data: this.stringData({ ...data, title, body }),
                android: { priority: 'HIGH' },
              }
            : {
                token,
                notification: avatar
                  ? { title, body, image: avatar }
                  : { title, body },
                data: this.stringData(data),
                android: {
                  priority: 'HIGH',
                  notification: avatar
                    ? { channel_id: 'obic_messages', image: avatar }
                    : { channel_id: 'obic_messages' },
                },
              },
        }),
      },
    );
  }

  private stringData(data?: Record<string, unknown>) {
    const out: Record<string, string> = {};
    if (!data) return out;
    for (const [key, value] of Object.entries(data)) {
      if (value == null) continue;
      out[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }
    return out;
  }

  private appleJwt(): string | null {
    const now = Math.floor(Date.now() / 1000);
    if (this.apnsJwt && now - this.apnsJwt.at < 2400) return this.apnsJwt.token;
    const keyId = this.config.get<string>('APNS_KEY_ID')?.trim();
    const teamId = this.config.get<string>('APNS_TEAM_ID')?.trim();
    const inline = this.config.get<string>('APNS_KEY')?.trim();
    const keyPath = this.config.get<string>('APNS_KEY_PATH')?.trim();
    if (!keyId || !teamId || (!inline && !keyPath)) return null;
    let key: string;
    if (inline) {
      key = inline.replace(/\\n/g, '\n');
    } else {
      try {
        key = readFileSync(keyPath!, 'utf8');
      } catch {
        return null;
      }
    }
    const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: keyId })).toString(
      'base64url',
    );
    const claims = Buffer.from(JSON.stringify({ iss: teamId, iat: now })).toString(
      'base64url',
    );
    const signer = createSign('SHA256');
    signer.update(`${header}.${claims}`);
    signer.end();
    const sig = ecdsaDerToJose(signer.sign(key)).toString('base64url');
    const token = `${header}.${claims}.${sig}`;
    this.apnsJwt = { token, at: now };
    return token;
  }

  private async googleAccessToken(): Promise<string | null> {
    const now = Math.floor(Date.now() / 1000);
    if (this.fcmJwt && now - this.fcmJwt.at < 2400) return this.fcmJwt.token;
    const inline = this.config.get<string>('FCM_SERVICE_ACCOUNT_JSON')?.trim();
    const path = this.config.get<string>('FCM_SERVICE_ACCOUNT_PATH')?.trim();
    if (!inline && !path) return null;
    let account: { client_email?: string; private_key?: string };
    try {
      const raw = inline ?? readFileSync(path!, 'utf8');
      account = JSON.parse(raw) as {
        client_email?: string;
        private_key?: string;
      };
    } catch {
      return null;
    }
    if (!account.client_email || !account.private_key) return null;
    const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString(
      'base64url',
    );
    const claims = Buffer.from(
      JSON.stringify({
        iss: account.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      }),
    ).toString('base64url');
    const signer = createSign('RSA-SHA256');
    signer.update(`${header}.${claims}`);
    signer.end();
    const assertion = `${header}.${claims}.${signer.sign(account.private_key).toString('base64url')}`;
    const res = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });
    if (!res.ok) return null;
    const json = (await res.json()) as { access_token?: string };
    if (!json.access_token) return null;
    this.fcmJwt = { token: json.access_token, at: now };
    return json.access_token;
  }
}

/** Apple JWT wants raw R||S, not the DER signature Node returns. */
function ecdsaDerToJose(der: Buffer): Buffer {
  let offset = 2;
  if (der[1] & 0x80) offset = 2 + (der[1] & 0x7f);
  const rLen = der[offset + 1];
  let r = der.subarray(offset + 2, offset + 2 + rLen);
  offset = offset + 2 + rLen;
  const sLen = der[offset + 1];
  let s = der.subarray(offset + 2, offset + 2 + sLen);
  if (r[0] === 0) r = r.subarray(1);
  if (s[0] === 0) s = s.subarray(1);
  const out = Buffer.alloc(64);
  r.copy(out, 32 - r.length);
  s.copy(out, 64 - s.length);
  return out;
}
