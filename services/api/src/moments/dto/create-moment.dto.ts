// Made by Dr Ali
// Create moment — text and/or multi media (WeChat-style).

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class MomentMediaDto {
  @IsIn(['image', 'video', 'file'])
  kind!: 'image' | 'video' | 'file';

  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  url!: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  mime?: string;

  @IsOptional()
  @IsInt()
  size?: number;
}

export class CreateMomentDto {
  /** Required unless media is non-empty. */
  @ValidateIf((o: CreateMomentDto) => !o.media?.length)
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  body?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @ValidateNested({ each: true })
  @Type(() => MomentMediaDto)
  media?: MomentMediaDto[];
}
