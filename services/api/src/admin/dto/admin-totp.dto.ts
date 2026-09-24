// Made by Dr Ali
// SuperAdmin TOTP enroll / confirm / disable.

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class TotpConfirmDto {
  @ApiProperty({ example: '123456' })
  @IsString()
  @Matches(/^\d{6}$/)
  code!: string;
}

export class TotpDisableDto {
  @ApiProperty()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Matches(/^\d{6}$/)
  code!: string;
}

export class TotpEnrollResponseDto {
  @ApiProperty()
  otpauthUrl!: string;

  @ApiProperty({ description: 'Base32 secret — show once for manual entry' })
  secret!: string;
}

export class TotpStatusDto {
  @ApiProperty()
  enabled!: boolean;

  @ApiProperty()
  pendingEnroll!: boolean;
}
