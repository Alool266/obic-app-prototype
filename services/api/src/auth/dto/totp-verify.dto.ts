// Made by Dr Ali
// Complete login after password + TOTP challenge.

import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length, Matches } from 'class-validator';

export class TotpVerifyDto {
  @ApiProperty({ description: 'Short-lived token from login when requiresTotp is true' })
  @IsString()
  @Length(20, 4096)
  totpSession!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Matches(/^\d{6}$/, { message: 'code must be 6 digits' })
  code!: string;
}
