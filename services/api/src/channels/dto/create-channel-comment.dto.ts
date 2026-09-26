// Made by Dr Ali

import { IsString, MaxLength, MinLength } from 'class-validator';

export class CreateChannelCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;
}
