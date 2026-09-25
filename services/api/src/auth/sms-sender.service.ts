// Made by Dr Ali
// SMS OTP — Twilio free trial when set; otherwise trial log (+ optional email backup).

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MailSenderService } from './mail-sender.service';

export type SmsDeliveryResult =
  | { ok: true; via: 'twilio' | 'log' | 'email_backup' }
  | { ok: false; error: string };

@Injectable()
export class SmsSenderService {
  private readonly log = new Logger(SmsSenderService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly mail: MailSenderService,
  ) {}

  async sendOtpSms(opts: {
    toPhone: string;
    code: string;
    purpose: string;
    /** If SMS unavailable, optionally email the code (trial / freemium). */
    backupEmail?: string | null;
    locale?: string | null;
  }): Promise<SmsDeliveryResult> {
    const sid = (this.config.get<string>('TWILIO_ACCOUNT_SID') ?? '').trim();
    const token = (this.config.get<string>('TWILIO_AUTH_TOKEN') ?? '').trim();
    const from = (this.config.get<string>('TWILIO_FROM_NUMBER') ?? '').trim();

    const body = `【OBIC】验证码 ${opts.code}，10分钟内有效。如非本人操作请忽略。`;

    if (sid && token && from) {
      try {
        const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
        const auth = Buffer.from(`${sid}:${token}`).toString('base64');
        const form = new URLSearchParams({
          To: opts.toPhone,
          From: from,
          Body: body,
        });
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            Authorization: `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: form.toString(),
        });
        if (!res.ok) {
          const t = await res.text();
          this.log.error(`Twilio failed ${res.status}: ${t.slice(0, 200)}`);
        } else {
          return { ok: true, via: 'twilio' };
        }
      } catch (e) {
        this.log.error(`Twilio error: ${String(e)}`);
      }
    }

    if (opts.backupEmail) {
      const mailed = await this.mail.sendOtpEmail({
        to: opts.backupEmail,
        code: opts.code,
        purpose: `${opts.purpose}_phone_backup`,
        locale: opts.locale,
      });
      if (mailed.ok) {
        this.log.warn(
          `[trial] SMS unset/failed — emailed phone OTP to ${opts.backupEmail}`,
        );
        return { ok: true, via: 'email_backup' };
      }
    }

    this.log.warn(
      `[trial] TWILIO_* unset — phone OTP for ${opts.toPhone} (${opts.purpose}): ${opts.code}`,
    );
    return { ok: true, via: 'log' };
  }
}
