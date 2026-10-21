// Made by Dr Ali

import { IsBoolean, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

const DATE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
const CLOCK = /^([01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?$/;

export class SaveCalendarEventDto {
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
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
