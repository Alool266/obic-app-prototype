// Made by Dr Ali
// Create moment comment — text and/or photos (WeChat Moments style).

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class MomentCommentMediaDto {
  @IsIn(['image'])
  kind!: 'image';

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

export class CreateMomentCommentDto {
  /** Required unless media is non-empty. */
  @ValidateIf((o: CreateMomentCommentDto) => !o.media?.length)
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  body?: string;

  /** Optional: reply to this comment on the same moment (WeChat-style). */
  @IsOptional()
  @IsUUID()
  replyToCommentId?: string;

  /** WeChat Moments comment photos — images only, up to 9. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @ValidateNested({ each: true })
  @Type(() => MomentCommentMediaDto)
  media?: MomentCommentMediaDto[];
}
