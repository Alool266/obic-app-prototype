// Made by Dr Ali
// WeChat-style phone sign-in — phone number + SMS code, no password.
// The service normalizes/validates the number (CN +86, SA +966, YE +967).

import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class PhoneLoginStartDto {
  @IsString()
  @MaxLength(32)
  phone!: string;

  /** Optional UI locale for the SMS text (ar | en | zh | fr). */
  @IsOptional()
  @IsString()
  @IsIn(['ar', 'en', 'zh', 'fr'])
  locale?: string;

  /** Client region (ISO 3166-1 alpha-2), stored on new accounts. */
  @IsOptional()
  @IsString()
  @MaxLength(8)
  regionCountry?: string;
}
