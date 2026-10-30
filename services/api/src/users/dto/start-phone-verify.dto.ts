// Made by Dr Ali
// Start China phone OTP for logged-in users (add / re-verify).
// Trial: code goes to account email; production may use SMS when env keys set.

import { IsEmail, IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class StartPhoneVerifyDto {
  /** China +86, Saudi Arabia +966, or Yemen +967 mobile. */
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$|^(?:\+?966)?0?5\d{8}$|^(?:\+?967)?0?7\d{8}$/, {
    message: 'SMS_PHONE_COUNTRIES',
  })
  phone!: string;

  /**
   * Required when the account has no email yet (trial sends OTP to email).
   * Ignored if the user already has an email on file.
   */
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @IsIn(['ar', 'en', 'zh'])
  locale?: string;
}
