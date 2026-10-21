// Made by Dr Ali

import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { MEETING_ATTENDEE_LIMIT } from '../company-meeting';

const DATE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
const CLOCK = /^([01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?$/;

export class SaveMeetingDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  title!: string;

  @IsString()
  @Matches(DATE)
  date!: string;

  @IsString()
  @Matches(CLOCK)
  start!: string;

  @IsString()
  @Matches(CLOCK)
  end!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  agenda?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(MEETING_ATTENDEE_LIMIT + 1)
  @IsUUID('4', { each: true })
  userIds!: string[];
}
