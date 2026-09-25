// Made by Dr Ali
// Moments notify prefs DTO — global toggles + optional muted-friend list replace.

import {
  IsArray,
  IsBoolean,
  IsOptional,
  IsUUID,
} from 'class-validator';

export class UpdateMomentNotifyPrefsDto {
  @IsOptional()
  @IsBoolean()
  notifyEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  muteUpdates?: boolean;

  /** When set, replaces the full muted-friend set for this user. */
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  mutedFriendIds?: string[];
}
