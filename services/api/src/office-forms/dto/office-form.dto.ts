// Made by Dr Ali

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class OfficeFormFieldDto {
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  key!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  labelEn!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  labelAr!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  labelZh!: string;

  @IsIn(['short_text', 'long_text', 'number', 'choice'])
  type!: 'short_text' | 'long_text' | 'number' | 'choice';

  @IsBoolean()
  required!: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsString({ each: true })
  @MaxLength(80, { each: true })
  options?: string[];
}

export class SaveOfficeFormDto {
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

  @IsBoolean()
  active!: boolean;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(12)
  @ValidateNested({ each: true })
  @Type(() => OfficeFormFieldDto)
  fields!: OfficeFormFieldDto[];
}

export class SubmitOfficeFormDto {
  @IsUUID('4')
  formId!: string;

  @IsObject()
  answers!: Record<string, string>;
}
