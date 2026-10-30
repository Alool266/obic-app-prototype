// Made by Dr Ali

import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SaveCompanyTagDto {
  @IsString()
  @MinLength(1)
  @MaxLength(24)
  name!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class SetContactTagsDto {
  @IsArray()
  @ArrayMaxSize(8)
  @IsUUID('4', { each: true })
  tagIds!: string[];
}
