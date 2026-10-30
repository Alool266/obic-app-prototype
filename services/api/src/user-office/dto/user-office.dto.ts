// Made by Dr Ali
// Personal office item create / update / share.

import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateUserOfficeDto {
  @IsIn(['note', 'document', 'spreadsheet', 'pdf'])
  kind!: 'note' | 'document' | 'spreadsheet' | 'pdf';

  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200_000)
  body?: string;

  @IsOptional()
  @IsArray()
  grid?: string[][];

  @IsOptional()
  @IsString()
  @MaxLength(500)
  fileUrl?: string;
}

export class UpdateUserOfficeDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200_000)
  body?: string;

  @IsOptional()
  @IsArray()
  grid?: string[][];

  @IsOptional()
  @IsString()
  @MaxLength(500)
  fileUrl?: string;
}

export class ShareUserOfficeDto {
  @IsArray()
  @ArrayMaxSize(40)
  @IsUUID('4', { each: true })
  shareUserIds!: string[];
}
