// Made by Dr Ali
// Whitelist bodies — never accept actor ids from the client for AuthZ.

import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  ReportStatus,
  ReportTargetType,
} from '../content-report.entity';

export class CreateReportDto {
  @IsEnum(ReportTargetType)
  targetType!: ReportTargetType;

  @IsUUID()
  targetId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class ReviewReportDto {
  @IsEnum(ReportStatus)
  status!: ReportStatus;
}

export class CreateBannedWordDto {
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  phrase!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;
}
