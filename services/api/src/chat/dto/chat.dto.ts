// Made by Dr Ali

import { IsBoolean, IsIn, IsOptional, IsString, IsUUID, MaxLength, ValidateIf } from 'class-validator';

export class CreateThreadDto {
  /** Peer user id for a direct thread (omit for support). */
  @IsOptional()
  @IsUUID()
  peerUserId?: string;

  @IsOptional()
  @IsIn(['direct', 'support', 'group'])
  kind?: 'direct' | 'support' | 'group';

  /** Group title (required when kind=group). */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  /** Extra member user ids for group (creator is always included). */
  @IsOptional()
  @IsUUID('4', { each: true })
  memberUserIds?: string[];
}

export class SendMessageDto {
  @ValidateIf((o: SendMessageDto) => !o.attachmentKind || o.attachmentKind === 'none')
  @IsString()
  @MaxLength(8000)
  body?: string;

  @IsOptional()
  @IsIn(['none', 'image', 'file'])
  attachmentKind?: 'none' | 'image' | 'file';

  @IsOptional()
  @IsString()
  @MaxLength(255)
  attachmentName?: string;

  /** Public URL from POST /v1/uploads (http(s) or /uploads/…). stub:// rejected. */
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  attachmentUrl?: string;

  /**
   * Optional app UI locale (ar | en | zh) for AI auto-reply fallback.
   * Reply language still follows the message text; this is only when script is unclear.
   */
  @IsOptional()
  @IsIn(['ar', 'en', 'zh'])
  locale?: 'ar' | 'en' | 'zh';
}

export class RequestStaffDto {
  @IsOptional()
  @IsIn(['ar', 'en', 'zh'])
  locale?: 'ar' | 'en' | 'zh';

  /**
   * Support handoff: Form2 branch id (Yiwu, Guangzhou, …).
   * Required for support threads (client form). Order threads ignore this.
   */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  branch?: string;

  /**
   * Form1/Form2 service slug (visa, business, …) or seed desk key
   * (secretary, marketing, …). Mapped via order-routing deskKeyForServiceSlug.
   */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  serviceKey?: string;

  /** Alias for serviceKey — desk key or service slug. */
  @IsOptional()
  @IsString()
  @MaxLength(64)
  desk?: string;

  /** Optional order / visa / case reference (prefilled from auto-intent). */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  orderRef?: string;

  /** Optional short note for staff notification. */
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class UpdateThreadPrefsDto {
  @IsOptional()
  @IsBoolean()
  muted?: boolean;

  @IsOptional()
  @IsBoolean()
  hidden?: boolean;

  /** Clear local history for me (server clears via clearedBefore). */
  @IsOptional()
  @IsBoolean()
  clearHistory?: boolean;

  /** Hide + mute + clear (WeChat delete chat). */
  @IsOptional()
  @IsBoolean()
  deleteChat?: boolean;
}
