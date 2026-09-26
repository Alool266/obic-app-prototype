// Made by Dr Ali
// Create a short Channel video (URL from POST /v1/uploads).

import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

/** Hard limits for OBIC Channel shorts (enforced server-side). */
export const CHANNEL_VIDEO_MAX_BYTES = 40 * 1024 * 1024; // 40 MB
export const CHANNEL_VIDEO_MAX_DURATION_SEC = 60;

export class CreateChannelVideoDto {
  /** Absolute http(s) or /uploads/… path from POST /v1/uploads. */
  @IsString()
  @MaxLength(1024)
  videoUrl!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  thumbUrl?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  caption?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(CHANNEL_VIDEO_MAX_DURATION_SEC)
  durationSec?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(CHANNEL_VIDEO_MAX_BYTES)
  byteSize?: number;
}
