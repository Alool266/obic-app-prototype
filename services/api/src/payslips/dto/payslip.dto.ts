// Made by Dr Ali

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class PayslipLineDto {
  @IsString()
  @Matches(/^[a-z][a-z0-9_]{0,31}$/)
  key!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  label!: string;

  @IsIn(['earning', 'deduction'])
  kind!: 'earning' | 'deduction';

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100_000_000)
  cents!: number;
}

export class SavePayslipDto {
  @IsUUID('4')
  userId!: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}$/)
  period!: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  note?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(12)
  @ValidateNested({ each: true })
  @Type(() => PayslipLineDto)
  lines!: PayslipLineDto[];
}
