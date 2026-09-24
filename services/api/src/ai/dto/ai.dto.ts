// Made by Dr Ali

import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class AiHistoryTurnDto {
  @IsIn(['user', 'assistant'])
  role!: 'user' | 'assistant';

  @IsString()
  @MaxLength(4000)
  content!: string;
}

export class AiAssistantDto {
  @IsString()
  @MaxLength(4000)
  message!: string;

  /**
   * App UI locale preference: ar | en | zh (defaults from Accept-Language / en).
   * Reply language still follows the user's latest message (any language);
   * this is only the fallback when the message language is unclear.
   */
  @IsOptional()
  @IsIn(['ar', 'en', 'zh'])
  locale?: 'ar' | 'en' | 'zh';

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ValidateNested({ each: true })
  @Type(() => AiHistoryTurnDto)
  history?: AiHistoryTurnDto[];

  /** Existing server thread id — must belong to the caller (IDOR-safe). */
  @IsOptional()
  @IsUUID()
  threadId?: string;
}

/** WeChat-style message translation (AR / EN / ZH). */
export class AiTranslateDto {
  @IsString()
  @MaxLength(4000)
  text!: string;

  /** Target language for the translation. */
  @IsIn(['ar', 'en', 'zh'])
  targetLocale!: 'ar' | 'en' | 'zh';

  /** Optional chat message id — used for server-side cache key. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  messageId?: string;
}

export class SetAiAutoReplyDto {
  @IsBoolean()
  enabled!: boolean;
}
