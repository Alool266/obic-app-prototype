// Made by Dr Ali
// Refresh / logout body — opaque refresh token only (never log it).

import { IsString, MinLength } from 'class-validator';

export class RefreshDto {
  @IsString()
  @MinLength(16)
  refreshToken!: string;
}

export class LogoutDto {
  @IsString()
  @MinLength(16)
  refreshToken!: string;
}
