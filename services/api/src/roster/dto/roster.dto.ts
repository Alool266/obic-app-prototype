// Made by Dr Ali

import {
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

const DAY = /^\d{4}-\d{2}-\d{2}$/;

export class RecordJoinDto {
  @IsUUID('4')
  userId!: string;

  @IsString()
  @Matches(DAY)
  joinedOn!: string;
}

export class RequestLeaveDto {
  @IsString()
  @Matches(DAY)
  lastDay!: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  note?: string;
}
