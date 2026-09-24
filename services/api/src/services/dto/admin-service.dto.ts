// Made by Dr Ali
// SuperAdmin catalog CRUD — validated payloads.

import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class AdminCreateServiceDto {
  @IsString()
  @MaxLength(64)
  slug!: string;

  @IsString()
  @MaxLength(32)
  icon!: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  colorKey?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsString()
  @MaxLength(120)
  nameAr!: string;

  @IsString()
  @MaxLength(120)
  nameEn!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameZh?: string;

  @IsString()
  descAr!: string;

  @IsString()
  descEn!: string;

  @IsOptional()
  @IsString()
  descZh?: string;

  @IsString()
  @MaxLength(80)
  priceAr!: string;

  @IsString()
  @MaxLength(80)
  priceEn!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  priceZh?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  /** Comma-separated ISO country codes; empty = worldwide. */
  @IsOptional()
  @IsString()
  countries?: string;
}

export class AdminUpdateServiceDto {
  @IsOptional()
  @IsString()
  @MaxLength(64)
  slug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  icon?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  colorKey?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  nameZh?: string;

  @IsOptional()
  @IsString()
  descAr?: string;

  @IsOptional()
  @IsString()
  descEn?: string;

  @IsOptional()
  @IsString()
  descZh?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  priceAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  priceEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  priceZh?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  /** Comma-separated ISO country codes; empty = worldwide. */
  @IsOptional()
  @IsString()
  countries?: string;
}
