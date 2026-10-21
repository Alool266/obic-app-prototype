// Made by Dr Ali

import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateCallDto {
  @IsUUID()
  conversationId!: string;

  @IsIn(['voice', 'video'])
  mode!: 'voice' | 'video';

  /** Group only. Omit to ring every other member. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(15)
  @IsUUID('4', { each: true })
  inviteUserIds?: string[];
}

export class InviteCallDto {
  @IsArray()
  @ArrayMaxSize(15)
  @IsUUID('4', { each: true })
  userIds!: string[];
}

export class CallTokenDto {
  /** Optional; server derives a stable Agora uid from JWT user when omitted. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  clientHint?: string;
}
