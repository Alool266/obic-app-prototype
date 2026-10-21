// Made by Dr Ali
// Website OBIC AI. No account. Does not read or write app chat history.

import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Post,
  Req,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { parseAiAttachment } from './ai-attachment';
import { AiService } from './ai.service';
import { AiAssistantDto, AiTranslateDto } from './dto/ai.dto';

@Controller('ai/public')
export class AiPublicController {
  constructor(private readonly ai: AiService) {}

  /** One bucket per visitor. Not a user id, and not stored. */
  private callerKey(req: Request): string {
    const forwarded = req.headers['x-forwarded-for'];
    const raw = Array.isArray(forwarded) ? forwarded[0] : forwarded;
    const ip = (raw?.split(',')[0] || req.ip || 'unknown').trim().slice(0, 80);
    return `web:${ip}`;
  }

  @Get('status')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  status() {
    return this.ai.statusAsync();
  }

  @Post('assistant')
  @HttpCode(200)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  async assistant(
    @Req() req: Request,
    @Body() dto: AiAssistantDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    const locale =
      dto.locale ??
      this.ai.resolveLocale(acceptLanguage?.split(',')[0] ?? 'en');

    const status = await this.ai.statusAsync();
    if (!status.enabled) {
      return {
        enabled: false,
        locale,
        reply: this.ai.disabledCopy(locale),
      };
    }

    const message = dto.message.trim();
    const attachment = dto.attachment
      ? parseAiAttachment(dto.attachment)
      : undefined;
    if (!message && !attachment) {
      throw new BadRequestException('Message is empty');
    }

    const reply = await this.ai.complete({
      userId: this.callerKey(req),
      locale,
      userMessage: message,
      history: dto.history,
      purpose: 'assistant',
      attachment,
    });

    return {
      enabled: true,
      locale,
      reply,
    };
  }

  @Post('translate')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  async translate(@Req() req: Request, @Body() dto: AiTranslateDto) {
    const targetLocale = this.ai.resolveLocale(dto.targetLocale);
    const status = await this.ai.statusAsync();
    if (!status.enabled) {
      return {
        enabled: false,
        targetLocale,
        translation: this.ai.disabledCopy(targetLocale),
        cached: false,
      };
    }

    const result = await this.ai.translate({
      userId: this.callerKey(req),
      text: dto.text,
      targetLocale,
      messageId: null,
    });

    return {
      enabled: true,
      targetLocale: result.targetLocale,
      translation: result.translation,
      cached: result.cached,
    };
  }
}
