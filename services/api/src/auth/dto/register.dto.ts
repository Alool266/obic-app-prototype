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

  /** China mainland mobile only (+86 / 1[3-9]xxxxxxxxx). */
  @ValidateIf((o: RegisterDto) => !o.email)
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$/, {
    message: 'Phone verification supports China numbers only for now',
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
}
