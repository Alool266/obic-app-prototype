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

export class SaveCompanyGroupDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsArray()
  @ArrayMaxSize(80)
  @IsUUID('4', { each: true })
  contactIds!: string[];
}

export class AdminSaveCompanyGroupDto extends SaveCompanyGroupDto {
  @IsUUID('4')
  ownerUserId!: string;
}
