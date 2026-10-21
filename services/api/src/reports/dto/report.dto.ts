// Made by Dr Ali

import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SubmitReportDto {
  @IsIn(['daily', 'weekly', 'monthly'])
  kind!: 'daily' | 'weekly' | 'monthly';

  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  done!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  plan!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  blockers?: string;
}

export class UpdateReportReviewersDto {
  @IsString()
  @MaxLength(64)
  timezone!: string;

  @IsArray()
  @ArrayMaxSize(12)
  @IsUUID('4', { each: true })
  reviewerIds!: string[];
}
