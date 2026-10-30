// Made by Dr Ali

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsObject,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { OfficeFormFieldDto } from '../../office-forms/dto/office-form.dto';

export class SaveCollectionFormDto {
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

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(80)
  @IsUUID('4', { each: true })
  audienceIds!: string[];
}

export class SubmitCollectionFormDto {
  @IsObject()
  answers!: Record<string, string>;
}
