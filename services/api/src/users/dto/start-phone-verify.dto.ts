// Made by Dr Ali
// Start China phone OTP for logged-in users (add / re-verify).
// Trial: code goes to account email; production may use SMS when env keys set.

import { IsEmail, IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class StartPhoneVerifyDto {
  /** China mainland mobile only (+86 / 1[3-9]xxxxxxxxx). */
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$/, {
    message: 'Phone verification supports China numbers only for now',
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
