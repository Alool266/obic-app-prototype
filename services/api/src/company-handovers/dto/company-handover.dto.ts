// Made by Dr Ali

import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';
import { HANDOVER_LIMIT } from '../company-handover';

export class CreateHandoverDto {
  @IsUUID('4')
  fromUserId!: string;

  @IsUUID('4')
  toUserId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(HANDOVER_LIMIT)
  @IsUUID('4', { each: true })
  contactIds!: string[];
}
