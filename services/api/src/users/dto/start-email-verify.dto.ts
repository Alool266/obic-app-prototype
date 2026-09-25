// Made by Dr Ali
// Start email OTP for logged-in China cohort (or add email then verify).

import { IsEmail, IsIn, IsOptional, IsString } from 'class-validator';

export class StartEmailVerifyDto {
  /**
   * Required when the account has no email yet.
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
