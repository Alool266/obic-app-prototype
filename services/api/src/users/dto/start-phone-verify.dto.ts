// Made by Dr Ali
// Start China phone SMS OTP for logged-in users (add / re-verify).

import { IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class StartPhoneVerifyDto {
  /** China mainland mobile only (+86 / 1[3-9]xxxxxxxxx). */
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$/, {
    message: 'Phone verification supports China numbers only for now',
  })
  phone!: string;

  @IsOptional()
  @IsString()
  @IsIn(['ar', 'en', 'zh'])
  locale?: string;
}
