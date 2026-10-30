// Made by Dr Ali
// Moments notify prefs DTO — global toggles + mute + hide-from lists.

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

  /** When set, replaces the full muted-friend set for this user (不看他). */
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  mutedFriendIds?: string[];

  /** When set, replaces friends who cannot see my Moments (不让他看). */
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  hiddenFromFriendIds?: string[];
}
