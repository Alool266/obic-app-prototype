// Made by Dr Ali
// Register — email OR China mainland phone + password + name.

import {
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class RegisterDto {
  @ValidateIf((o: RegisterDto) => !o.phone)
  @IsEmail()
  @IsOptional()
  email?: string;

  /** China +86, Saudi Arabia +966, or Yemen +967 mobile. */
  @ValidateIf((o: RegisterDto) => Boolean(o.phone?.trim()))
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$|^(?:\+?966)?0?5\d{8}$|^(?:\+?967)?0?7\d{8}$/, {
    message: 'SMS_PHONE_COUNTRIES',
  })
  @IsOptional()
  phone?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name!: string;

  /** Optional UI locale for OTP email (ar | en | zh). */
  @IsOptional()
  @IsString()
  @IsIn(['ar', 'en', 'zh'])
  locale?: string;

  /**
   * Client region (ISO 3166-1 alpha-2). When CN/HK/MO (or zh locale),
   * register requires a China mainland mobile + SMS OTP.
   */
  @IsOptional()
  @IsString()
  @MaxLength(8)
  regionCountry?: string;
}
