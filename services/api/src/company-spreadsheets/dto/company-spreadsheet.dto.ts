// Made by Dr Ali

import { ArrayMaxSize, ArrayMinSize, IsArray, IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { SHEET_ROWS } from '../company-spreadsheet';

export class SaveSheetGridDto {
  @IsArray()
  @ArrayMinSize(SHEET_ROWS)
  @ArrayMaxSize(SHEET_ROWS)
  rows!: unknown[];
}

export class SaveSheetDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  title!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(SHEET_ROWS)
  @ArrayMaxSize(SHEET_ROWS)
  rows?: unknown[];
}
