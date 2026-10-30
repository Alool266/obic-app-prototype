// Made by Dr Ali

import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class PunchDto {
  @IsIn(['in', 'out'])
  kind!: 'in' | 'out';

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}

export class UpdateAttendanceRuleDto {
  @IsString()
  @MaxLength(64)
  timezone!: string;

  @IsInt()
  @Min(0)
  @Max(1439)
  startMinute!: number;

  @IsInt()
  @Min(0)
  @Max(1439)
  endMinute!: number;

  @IsInt()
  @Min(0)
  @Max(180)
  graceMinutes!: number;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  weekdays!: number[];
}
