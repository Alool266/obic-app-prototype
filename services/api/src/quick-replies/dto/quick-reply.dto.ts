// Made by Dr Ali

import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SaveQuickReplyDto {
  @IsString()
  @MinLength(1)
  @MaxLength(24)
  title!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(300)
  body!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
