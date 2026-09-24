// Made by Dr Ali
// SuperAdmin inner-service CRUD payloads.

import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class AdminCreateSubServiceDto {
  @IsUUID()
  serviceId!: string;

  @IsString()
  @MaxLength(80)
  externalId!: string;

  @IsString()
  @MaxLength(32)
  icon!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsString()
  @MaxLength(160)
  nameAr!: string;

  @IsString()
  @MaxLength(160)
  nameEn!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
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

export class AdminUpdateSubServiceDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  externalId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  icon?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  nameAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  nameEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
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
