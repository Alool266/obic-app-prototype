// Made by Dr Ali

import { ArrayMaxSize, ArrayMinSize, IsArray, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { MAIL_RECIPIENT_LIMIT } from '../company-mail';

export class SendCompanyMailDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  subject!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(MAIL_RECIPIENT_LIMIT)
  @IsUUID('4', { each: true })
  userIds!: string[];
}
