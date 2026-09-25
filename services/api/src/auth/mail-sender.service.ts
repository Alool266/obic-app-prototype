// Made by Dr Ali
// Branded OBIC OTP email — Resend free tier; HTML AR/EN/ZH.

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export type EmailDeliveryResult =
  | { ok: true; via: 'resend' | 'log' }
  | { ok: false; error: string };

type MailLocale = 'ar' | 'en' | 'zh';

@Injectable()
export class MailSenderService {
  private readonly log = new Logger(MailSenderService.name);

  constructor(private readonly config: ConfigService) {}

  async sendOtpEmail(opts: {
    to: string;
    code: string;
    purpose: string;
    locale?: string | null;
  }): Promise<EmailDeliveryResult> {
    const apiKey = (this.config.get<string>('RESEND_API_KEY') ?? '').trim();
    const from =
      (this.config.get<string>('RESEND_FROM') ?? '').trim() ||
      'OBIC <onboarding@resend.dev>';
    const locale = this.normalizeLocale(opts.locale);
    const copy = this.copy(locale, opts.code);

    if (!apiKey) {
      this.log.warn(
        `[trial] RESEND_API_KEY unset — email OTP for ${opts.to} (${opts.purpose}): ${opts.code}`,
      );
      return { ok: true, via: 'log' };
    }

    try {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from,
          to: [opts.to],
          subject: copy.subject,
          text: copy.text,
          html: copy.html,
        }),
      });
      if (!res.ok) {
        const body = await res.text();
        this.log.error(`Resend failed ${res.status}: ${body.slice(0, 200)}`);
        this.log.warn(`[fallback-log] OTP for ${opts.to}: ${opts.code}`);
        return { ok: true, via: 'log' };
      }
      return { ok: true, via: 'resend' };
    } catch (e) {
      this.log.error(`Resend error: ${String(e)}`);
      this.log.warn(`[fallback-log] OTP for ${opts.to}: ${opts.code}`);
      return { ok: true, via: 'log' };
    }
  }

  private normalizeLocale(raw?: string | null): MailLocale {
    const v = (raw ?? 'en').toLowerCase().slice(0, 2);
    if (v === 'ar') return 'ar';
    if (v === 'zh') return 'zh';
    return 'en';
  }

  private copy(locale: MailLocale, code: string): {
    subject: string;
    text: string;
    html: string;
  } {
    const dir = locale === 'ar' ? 'rtl' : 'ltr';
    const strings = {
      en: {
        subject: 'Your OBIC verification code',
        hello: 'Welcome to OBIC',
        body: 'Enter this code in the app to verify your account:',
        expires: 'This code expires in 10 minutes.',
        ignore: 'If you did not request this, you can ignore this email.',
        brand: 'OBIC — China travel & business',
      },
      ar: {
        subject: 'رمز التحقق من OBIC',
        hello: 'مرحباً بك في OBIC',
        body: 'أدخل هذا الرمز في التطبيق للتحقق من حسابك:',
        expires: 'ينتهي هذا الرمز خلال 10 دقائق.',
        ignore: 'إذا لم تطلب هذا، يمكنك تجاهل الرسالة.',
        brand: 'OBIC — السفر والأعمال في الصين',
      },
      zh: {
        subject: '你的 OBIC 验证码',
        hello: '欢迎使用 OBIC',
        body: '请在应用中输入以下验证码以完成验证：',
        expires: '验证码 10 分钟内有效。',
        ignore: '如非本人操作，请忽略此邮件。',
        brand: 'OBIC — 中国出行与商务服务',
      },
    }[locale];

    const text = [
      strings.hello,
      '',
      strings.body,
      code,
      '',
      strings.expires,
      strings.ignore,
      '',
      strings.brand,
    ].join('\n');

    const html = `<!DOCTYPE html>
<html lang="${locale}" dir="${dir}">
<head><meta charset="utf-8"/><meta name="viewport" content="width=device-width"/></head>
<body style="margin:0;padding:0;background:#f0f2f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f0f2f5;padding:32px 12px;">
    <tr><td align="center">
      <table role="presentation" width="100%" style="max-width:440px;background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 8px 24px rgba(15,36,68,0.08);">
        <tr>
          <td style="background:#0F2444;padding:22px 24px;text-align:center;">
            <div style="display:inline-block;background:#1B3A6B;border-radius:10px;padding:10px 18px;">
              <span style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:2px;">OBIC</span>
              <div style="height:3px;width:36px;background:#2F6FED;margin:8px auto 0;border-radius:2px;"></div>
            </div>
          </td>
        </tr>
        <tr>
          <td style="padding:28px 28px 8px;text-align:${dir === 'rtl' ? 'right' : 'left'};">
            <p style="margin:0 0 10px;color:#0F2444;font-size:18px;font-weight:700;">${strings.hello}</p>
            <p style="margin:0 0 18px;color:#4A5568;font-size:15px;line-height:1.5;">${strings.body}</p>
            <div style="text-align:center;margin:8px 0 20px;">
              <div style="display:inline-block;background:#F4F7FB;border:1px solid #D7E0EC;border-radius:12px;padding:16px 28px;">
                <span style="font-size:32px;font-weight:800;letter-spacing:10px;color:#0F2444;font-family:ui-monospace,Menlo,Consolas,monospace;">${code}</span>
              </div>
            </div>
            <p style="margin:0 0 8px;color:#718096;font-size:13px;">${strings.expires}</p>
            <p style="margin:0 0 20px;color:#A0AEC0;font-size:12px;">${strings.ignore}</p>
          </td>
        </tr>
        <tr>
          <td style="padding:14px 24px 22px;border-top:1px solid #EEF2F7;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:11px;">${strings.brand}</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

    return { subject: strings.subject, text, html };
  }
}
