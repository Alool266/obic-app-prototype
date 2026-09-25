// Made by Dr Ali
// Moments album cover URL (WeChat-style header).

import { IsString, MaxLength } from 'class-validator';

export class UpdateMomentsCoverDto {
  /** Absolute or /uploads/… URL. Empty string clears. */
  @IsString()
  @MaxLength(1024)
  coverUrl!: string;
}
