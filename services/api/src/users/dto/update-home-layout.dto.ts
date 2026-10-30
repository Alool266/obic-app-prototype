// Made by Dr Ali
// PUT /v1/users/me/home-layout — service slugs + optional mini-apps shelf.

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';

const SLUG = /^[a-z0-9][a-z0-9_-]{0,62}$/;

export class MiniAppsLayoutDto {
  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  order!: string[];

  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  favorites!: string[];

  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  hidden!: string[];
}

export class UpdateHomeLayoutDto {
  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  order!: string[]; // client JSON key — mapped to orderSlugs on the entity

  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  favorites!: string[];

  @IsArray()
  @ArrayMaxSize(64)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  @Matches(SLUG, { each: true })
  hidden!: string[];

  /** Mini-app shelf (order / favorite / hidden). Omitted on PUT = leave as-is. */
  @IsOptional()
  @ValidateNested()
  @Type(() => MiniAppsLayoutDto)
  miniApps?: MiniAppsLayoutDto;
}
