// Made by Dr Ali
// Moments album cover URL + vertical focus (WeChat-style pan/adjust).

import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpdateMomentsCoverDto {
  /** Absolute or /uploads/… URL. Empty string clears. */
  @IsString()
  @MaxLength(1024)
  coverUrl!: string;

  /**
   * Vertical Alignment.y for BoxFit.cover (−1 top … 0 center … 1 bottom).
   * Optional — omit to keep previous focus when only clearing URL edge cases.
   */
  @IsOptional()
  @IsNumber()
  @Min(-1)
  @Max(1)
  focusY?: number;
}
