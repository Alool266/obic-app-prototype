// Made by Dr Ali

import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateMomentCommentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  body!: string;

  /** Optional: reply to this comment on the same moment (WeChat-style). */
  @IsOptional()
  @IsUUID()
  replyToCommentId?: string;
}
