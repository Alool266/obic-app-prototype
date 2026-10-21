// Made by Dr Ali

import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { CONSULTATION_OPTIONS, TRIP_PURPOSES, TRIP_STATUSES } from '../vip';

export class CreateConsultationDto {
  @IsInt()
  @IsIn(CONSULTATION_OPTIONS.map((o) => o.minutes))
  minutes!: number;
}

export class CreateTripDto {
  @IsIn(TRIP_PURPOSES)
  purpose!: (typeof TRIP_PURPOSES)[number];

  @IsArray()
  @IsString({ each: true })
  cities!: string[];

  @IsInt()
  @Min(1)
  @Max(365)
  days!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  people?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  budgetCents?: number;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class QuoteTripDto {
  /** Extra Active PriceIDs (add-on services) chosen by the customer. */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  addonPriceIds?: string[];
}

export class MarkPaidDto {
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  reference!: string;
}

export class CreateGroupDto {
  /** Standing roster + responsible staff user IDs (customer added automatically). */
  @IsArray()
  @IsUUID('4', { each: true })
  memberUserIds!: string[];

  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;
}

export class AssignVipDto {
  @IsUUID()
  employeeId!: string;
}

export class TransitionTripDto {
  @IsIn(TRIP_STATUSES)
  status!: (typeof TRIP_STATUSES)[number];
}
