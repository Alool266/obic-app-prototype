// Made by Dr Ali

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class OfferMediaDto {
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

export class CreateOfferDto {
  /** Offer type slug: hotels | flights | future types. */
  @IsString()
  @Matches(/^[a-z][a-z0-9_-]{1,31}$/)
  kind!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  titleAr!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  titleEn!: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  bodyAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  bodyEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  priceLabelAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  priceLabelEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  locationLabel?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  datesLabel?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @ValidateNested({ each: true })
  @Type(() => OfferMediaDto)
  media?: OfferMediaDto[];

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @IsOptional()
  @IsBoolean()
  isSoldOut?: boolean;

  /** ISO-8601; omit or null = no expiry. */
  @IsOptional()
  @ValidateIf((_, v) => v !== null && v !== '')
  @IsDateString()
  expiresAt?: string | null;

  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;
}

export class UpdateOfferDto {
  @IsOptional()
  @IsString()
  @Matches(/^[a-z][a-z0-9_-]{1,31}$/)
  kind?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  titleAr?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  titleEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  bodyAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  bodyEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  priceLabelAr?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  priceLabelEn?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  locationLabel?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  datesLabel?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @ValidateNested({ each: true })
  @Type(() => OfferMediaDto)
  media?: OfferMediaDto[];

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @IsOptional()
  @IsBoolean()
  isSoldOut?: boolean;

  /** ISO-8601; pass null to clear expiry. */
  @IsOptional()
  @ValidateIf((_, v) => v !== null && v !== '')
  @IsDateString()
  expiresAt?: string | null;

  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;
}

/** Public + admin list filters. `type` is an alias of `kind`. */
export class OfferListQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(32)
  kind?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  type?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  q?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;
}
