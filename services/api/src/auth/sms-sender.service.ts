// Made by Dr Ali
// Phone OTP SMS — Aliyun / Tencent / Twilio when configured; honest trial fallbacks otherwise.
// Free +86 SMS quotas are rare; production should set a CN provider (Aliyun/Tencent preferred).

import { createHmac, createHash, randomUUID } from 'crypto';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MailSenderService } from './mail-sender.service';

export type SmsDeliveryVia =
  | 'sms'
  | 'aliyun'
  | 'tencent'
  | 'twilio'
  | 'log'
  | 'email_backup';

export type SmsDeliveryResult =
  | { ok: true; via: SmsDeliveryVia }
  | {
      ok: false;
      error: string;
      code?:
        | 'SMS_NOT_CONFIGURED'
        | 'SMS_SEND_FAILED'
        | 'EMAIL_REQUIRED_FOR_PHONE_VERIFY'
        | 'EMAIL_SEND_FAILED';
    };

@Injectable()
export class SmsSenderService {
  private readonly log = new Logger(SmsSenderService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly mail: MailSenderService,
  ) {}

  /**
   * Prefer real SMS (Aliyun → Tencent → Twilio) when env keys are set.
   * Trial (no SMS keys): email OTP only via Resend — never claims SMS was sent.
   * ~¥0.045–0.055/SMS typical mainland CN when production SMS is enabled.
   */
  async sendOtpSms(opts: {
    toPhone: string;
    code: string;
    purpose: string;
    backupEmail?: string | null;
    locale?: string | null;
  }): Promise<SmsDeliveryResult> {
    const providersConfigured =
      this.aliyunConfigured() ||
      this.tencentConfigured() ||
      this.twilioConfigured();

    for (const trySend of [
      () => this.tryAliyun(opts.toPhone, opts.code),
      () => this.tryTencent(opts.toPhone, opts.code),
      () => this.tryTwilio(opts.toPhone, opts.code),
    ]) {
      const result = await trySend();
      if (result?.ok) return result;
    }

    if (providersConfigured) {
      return {
        ok: false,
        error: 'SMS_SEND_FAILED',
        code: 'SMS_SEND_FAILED',
      };
    }

    // Trial path: email OTP only (phone binding confirmed via email code).
    const email = (opts.backupEmail ?? '').trim();
    if (!email) {
      return {
        ok: false,
        error: 'EMAIL_REQUIRED_FOR_PHONE_VERIFY',
        code: 'EMAIL_REQUIRED_FOR_PHONE_VERIFY',
      };
    }

    const mailed = await this.mail.sendOtpEmail({
      to: email,
      code: opts.code,
      purpose: `${opts.purpose}_phone_email`,
      locale: opts.locale,
    });
    if (mailed.ok) {
      this.log.log(
        `[trial] Phone verify OTP emailed to ${email} for ${opts.toPhone} (SMS later in production)`,
      );
      return { ok: true, via: 'email_backup' };
    }

    return {
      ok: false,
      error: 'EMAIL_SEND_FAILED',
      code: 'EMAIL_SEND_FAILED',
    };
  }

  private aliyunConfigured(): boolean {
    return Boolean(
      this.cfg('ALIYUN_SMS_ACCESS_KEY_ID') &&
        this.cfg('ALIYUN_SMS_ACCESS_KEY_SECRET') &&
        this.cfg('ALIYUN_SMS_SIGN_NAME') &&
        this.cfg('ALIYUN_SMS_TEMPLATE_CODE'),
    );
  }

  private tencentConfigured(): boolean {
    return Boolean(
      this.cfg('TENCENT_SMS_SECRET_ID') &&
        this.cfg('TENCENT_SMS_SECRET_KEY') &&
        this.cfg('TENCENT_SMS_SDK_APP_ID') &&
        this.cfg('TENCENT_SMS_SIGN_NAME') &&
        this.cfg('TENCENT_SMS_TEMPLATE_ID'),
    );
  }

  private twilioConfigured(): boolean {
    return Boolean(
      this.cfg('TWILIO_ACCOUNT_SID') &&
        this.cfg('TWILIO_AUTH_TOKEN') &&
        this.cfg('TWILIO_FROM_NUMBER'),
    );
  }

  private cfg(key: string): string {
    return (this.config.get<string>(key) ?? '').trim();
  }

  /** Mainland CN numbers as 11-digit local for Aliyun; E.164 for others. */
  private cnLocalOrE164(phone: string): { local: string; e164: string } {
    const digits = phone.replace(/[^\d]/g, '');
    let local = digits;
    if (local.startsWith('86') && local.length === 13) local = local.slice(2);
    const e164 = phone.startsWith('+') ? phone : `+${digits}`;
    return { local, e164 };
  }

  private async tryAliyun(
    toPhone: string,
    code: string,
  ): Promise<SmsDeliveryResult | null> {
    const accessKeyId = this.cfg('ALIYUN_SMS_ACCESS_KEY_ID');
    const accessKeySecret = this.cfg('ALIYUN_SMS_ACCESS_KEY_SECRET');
    const signName = this.cfg('ALIYUN_SMS_SIGN_NAME');
    const templateCode = this.cfg('ALIYUN_SMS_TEMPLATE_CODE');
    if (!accessKeyId || !accessKeySecret || !signName || !templateCode) {
      return null;
    }

    const { local } = this.cnLocalOrE164(toPhone);
    const templateParamKey =
      this.cfg('ALIYUN_SMS_TEMPLATE_PARAM_KEY') || 'code';
    try {
      const params: Record<string, string> = {
        AccessKeyId: accessKeyId,
        Action: 'SendSms',
        Format: 'JSON',
        PhoneNumbers: local,
        SignName: signName,
        SignatureMethod: 'HMAC-SHA1',
        SignatureNonce: randomUUID(),
        SignatureVersion: '1.0',
        TemplateCode: templateCode,
        TemplateParam: JSON.stringify({ [templateParamKey]: code }),
        Timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        Version: '2017-05-25',
      };
      const canonical = Object.keys(params)
        .sort()
        .map(
          (k) =>
            `${this.percentEncode(k)}=${this.percentEncode(params[k])}`,
        )
        .join('&');
      const stringToSign = `GET&${this.percentEncode('/')}&${this.percentEncode(canonical)}`;
      const signature = createHmac('sha1', `${accessKeySecret}&`)
        .update(stringToSign)
        .digest('base64');
      const url = `https://dysmsapi.aliyuncs.com/?${canonical}&Signature=${this.percentEncode(signature)}`;
      const res = await fetch(url, { method: 'GET' });
      const body = (await res.json()) as {
        Code?: string;
        Message?: string;
      };
      if (body.Code === 'OK') {
        return { ok: true, via: 'sms' };
      }
      this.log.error(
        `Aliyun SMS failed: ${body.Code ?? res.status} ${body.Message ?? ''}`.slice(
          0,
          200,
        ),
      );
      return {
        ok: false,
        error: body.Message ?? 'Aliyun SMS failed',
        code: 'SMS_SEND_FAILED',
      };
    } catch (e) {
      this.log.error(`Aliyun SMS error: ${String(e)}`);
      return { ok: false, error: String(e), code: 'SMS_SEND_FAILED' };
    }
  }

  private percentEncode(s: string): string {
    return encodeURIComponent(s)
      .replace(/\+/g, '%20')
      .replace(/\*/g, '%2A')
      .replace(/%7E/g, '~');
  }

  private async tryTencent(
    toPhone: string,
    code: string,
  ): Promise<SmsDeliveryResult | null> {
    const secretId = this.cfg('TENCENT_SMS_SECRET_ID');
    const secretKey = this.cfg('TENCENT_SMS_SECRET_KEY');
    const sdkAppId = this.cfg('TENCENT_SMS_SDK_APP_ID');
    const signName = this.cfg('TENCENT_SMS_SIGN_NAME');
    const templateId = this.cfg('TENCENT_SMS_TEMPLATE_ID');
    if (!secretId || !secretKey || !sdkAppId || !signName || !templateId) {
      return null;
    }

    const { e164 } = this.cnLocalOrE164(toPhone);
    const region = this.cfg('TENCENT_SMS_REGION') || 'ap-guangzhou';
    const host = 'sms.tencentcloudapi.com';
    const service = 'sms';
    const action = 'SendSms';
    const version = '2021-01-11';
    const timestamp = Math.floor(Date.now() / 1000);
    const date = new Date(timestamp * 1000).toISOString().slice(0, 10);
    const payload = JSON.stringify({
      PhoneNumberSet: [e164],
      SmsSdkAppId: sdkAppId,
      SignName: signName,
      TemplateId: templateId,
      TemplateParamSet: [code],
    });

    try {
      const hashedPayload = createHash('sha256').update(payload).digest('hex');
      const canonicalHeaders = `content-type:application/json; charset=utf-8\nhost:${host}\n`;
      const signedHeaders = 'content-type;host';
      const canonicalRequest = [
        'POST',
        '/',
        '',
        canonicalHeaders,
        signedHeaders,
        hashedPayload,
      ].join('\n');
      const credentialScope = `${date}/${service}/tc3_request`;
      const stringToSign = [
        'TC3-HMAC-SHA256',
        String(timestamp),
        credentialScope,
        createHash('sha256').update(canonicalRequest).digest('hex'),
      ].join('\n');
      const secretDate = createHmac('sha256', `TC3${secretKey}`)
        .update(date)
        .digest();
      const secretService = createHmac('sha256', secretDate)
        .update(service)
        .digest();
      const secretSigning = createHmac('sha256', secretService)
        .update('tc3_request')
        .digest();
      const signature = createHmac('sha256', secretSigning)
        .update(stringToSign)
        .digest('hex');
      const authorization = `TC3-HMAC-SHA256 Credential=${secretId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

      const res = await fetch(`https://${host}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Host: host,
          'X-TC-Action': action,
          'X-TC-Timestamp': String(timestamp),
          'X-TC-Version': version,
          'X-TC-Region': region,
          Authorization: authorization,
        },
        body: payload,
      });
      const body = (await res.json()) as {
        Response?: {
          Error?: { Code?: string; Message?: string };
          SendStatusSet?: Array<{ Code?: string; Message?: string }>;
        };
      };
      const err = body.Response?.Error;
      if (err) {
        this.log.error(
          `Tencent SMS failed: ${err.Code} ${err.Message}`.slice(0, 200),
        );
        return {
          ok: false,
          error: err.Message ?? 'Tencent SMS failed',
          code: 'SMS_SEND_FAILED',
        };
      }
      const status = body.Response?.SendStatusSet?.[0];
      if (status && status.Code && status.Code !== 'Ok') {
        this.log.error(
          `Tencent SMS status: ${status.Code} ${status.Message}`.slice(0, 200),
        );
        return {
          ok: false,
          error: status.Message ?? 'Tencent SMS failed',
          code: 'SMS_SEND_FAILED',
        };
      }
      return { ok: true, via: 'sms' };
    } catch (e) {
      this.log.error(`Tencent SMS error: ${String(e)}`);
      return { ok: false, error: String(e), code: 'SMS_SEND_FAILED' };
    }
  }

  private async tryTwilio(
    toPhone: string,
    code: string,
  ): Promise<SmsDeliveryResult | null> {
    const sid = this.cfg('TWILIO_ACCOUNT_SID');
    const token = this.cfg('TWILIO_AUTH_TOKEN');
    const from = this.cfg('TWILIO_FROM_NUMBER');
    if (!sid || !token || !from) return null;

    // Twilio trial rarely reaches +86; paid + geo permissions required for CN.
    const { e164 } = this.cnLocalOrE164(toPhone);
    const body = `【OBIC】验证码 ${code}，10分钟内有效。如非本人操作请忽略。`;
    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
      const auth = Buffer.from(`${sid}:${token}`).toString('base64');
      const form = new URLSearchParams({
        To: e164,
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
        return {
          ok: false,
          error: `Twilio ${res.status}`,
          code: 'SMS_SEND_FAILED',
        };
      }
      return { ok: true, via: 'sms' };
    } catch (e) {
      this.log.error(`Twilio error: ${String(e)}`);
      return { ok: false, error: String(e), code: 'SMS_SEND_FAILED' };
    }
  }
}
