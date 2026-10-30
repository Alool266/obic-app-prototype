// Made by Dr Ali

import {
  IsBoolean,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class SaveMeetingRoomDto {
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  nameEn!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  nameAr!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  nameZh!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  branchLabel?: string;

  @IsInt()
  @Min(1)
  @Max(200)
  capacity!: number;

  @IsBoolean()
  active!: boolean;
}

export class BookMeetingRoomDto {
  @IsUUID('4')
  roomId!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title!: string;

  @IsISO8601()
  startsAt!: string;

  @IsISO8601()
  endsAt!: string;
}
