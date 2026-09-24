// Made by Dr Ali

import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateCallDto {
  @IsUUID()
  conversationId!: string;

  @IsIn(['voice', 'video'])
  mode!: 'voice' | 'video';
}

export class CallTokenDto {
  /** Optional; server derives a stable Agora uid from JWT user when omitted. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  clientHint?: string;
}
