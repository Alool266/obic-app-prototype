// Made by Dr Ali

import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { PRICE_STATUSES, PRICING_BASES } from '../price';

export class CreatePriceVersionDto {
  @IsString()
  @Matches(/^[A-Z0-9][A-Z0-9-]{2,63}$/)
  priceId!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(32)
  version!: string;

  @IsString()
  @Matches(/^[a-z][a-z0-9-]{1,79}$/)
  serviceKey!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(160)
  itemName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  city?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  nationality?: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(2_000_000_000)
  obicFeeCents!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(2_000_000_000)
  externalFeeCents?: number;

  @IsOptional()
  @IsString()
  @Matches(/^[A-Z]{3}$/)
  currency?: string;

  @IsOptional()
  @IsIn(PRICING_BASES)
  pricingBasis?: (typeof PRICING_BASES)[number];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  effectiveFrom?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  effectiveTo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  sourceRef?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class TransitionPriceDto {
  @IsIn(PRICE_STATUSES)
  status!: (typeof PRICE_STATUSES)[number];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  effectiveFrom?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
