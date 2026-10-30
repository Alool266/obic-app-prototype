// Made by Dr Ali
// Create moment — text and/or multi media (WeChat-style) + privacy.

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { MOMENT_VISIBILITY_VALUES } from '../moment-visibility';

export class MomentMediaDto {
  @IsIn(['image', 'video', 'file'])
  kind!: 'image' | 'video' | 'file';

  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  url!: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  mime?: string;

  @IsOptional()
  @IsInt()
  size?: number;
}

export class CreateMomentDto {
  /** Required unless media is non-empty. */
  @ValidateIf((o: CreateMomentDto) => !o.media?.length)
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  body?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @ValidateNested({ each: true })
  @Type(() => MomentMediaDto)
  media?: MomentMediaDto[];

  /**
   * WeChat privacy: friends | private | partial | exclude.
   * Staff may also use public. Customers cannot set public.
   */
  @IsOptional()
  @IsIn([...MOMENT_VISIBILITY_VALUES])
  visibility?: (typeof MOMENT_VISIBILITY_VALUES)[number];

  /** Required when visibility=partial — specific friends who can see. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(500)
  @IsUUID('4', { each: true })
  allowedUserIds?: string[];

  /** Required when visibility=exclude — friends who cannot see. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(500)
  @IsUUID('4', { each: true })
  deniedUserIds?: string[];
}
