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

  /** Optional verification note shown on the recipient’s New Friends inbox. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  message?: string;
}
