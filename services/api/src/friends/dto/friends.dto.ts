// Made by Dr Ali

import { IsOptional, IsString, IsUUID, MaxLength, ValidateIf } from 'class-validator';

export class SendFriendRequestDto {
  /** Target by UUID or phone — at least one required. */
  @IsOptional()
  @IsUUID()
  userId?: string;

  @ValidateIf((o: SendFriendRequestDto) => !o.userId)
  @IsString()
  @MaxLength(32)
  phone?: string;
}
