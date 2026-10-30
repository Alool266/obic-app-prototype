// Made by Dr Ali
// /v1/ai — OBIC AI assistant + status + history (JWT). Keys never leave the server.

import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Headers,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { parseAiAttachment } from './ai-attachment';
import { AiHistoryService } from './ai-history.service';
import { AiService } from './ai.service';
import {
  AiAssistantDto,
  AiSeeTextDto,
  AiTranscribeDto,
  AiTranslateDto,
} from './dto/ai.dto';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(
    private readonly ai: AiService,
    private readonly history: AiHistoryService,
  ) {}

  private assertAiUser(actor: AuthUser) {
    if (
      actor.role !== UserRole.Customer &&
      actor.role !== UserRole.Employee &&
      actor.role !== UserRole.SuperAdmin
    ) {
      throw new ForbiddenException();
    }
  }

  @Get('status')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  status() {
    return this.ai.statusAsync();
  }

  @Get('assistant/threads')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  listThreads(@CurrentUser() actor: AuthUser) {
    this.assertAiUser(actor);
    return this.history.listThreads(actor.userId);
  }

  @Get('assistant/threads/:id')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  getThread(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    this.assertAiUser(actor);
    return this.history.getThread(actor.userId, id);
  }

  @Delete('assistant/threads/:id')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  deleteThread(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    this.assertAiUser(actor);
    return this.history.deleteThread(actor.userId, id);
  }

  @Post('assistant')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  async assistant(
    @CurrentUser() actor: AuthUser,
    @Body() dto: AiAssistantDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    this.assertAiUser(actor);

    const locale =
      dto.locale ??
      this.ai.resolveLocale(acceptLanguage?.split(',')[0] ?? 'en');

    const status = await this.ai.statusAsync();
    if (!status.enabled) {
      return {
        enabled: false,
        locale,
        reply: this.ai.disabledCopy(locale),
        threadId: dto.threadId ?? null,
      };
    }

    const message = dto.message.trim();
    const attachment = dto.attachment
      ? parseAiAttachment(dto.attachment)
      : undefined;
    if (!message && !attachment) {
      throw new BadRequestException('Message is empty');
    }

    const replyLocale = this.ai.resolveReplyLocale(message, locale);
    const reply = await this.ai.complete({
      userId: actor.userId,
      locale,
      userMessage: message,
      history: dto.history,
      purpose: 'assistant',
      attachment,
    });

    const historyText =
      message ||
      (attachment ? `[${attachment.kind}] ${attachment.filename}` : '');

    let threadId: string | null = dto.threadId ?? null;
    try {
      const saved = await this.history.appendExchange({
        userId: actor.userId,
        threadId: dto.threadId,
        userMessage: historyText,
        assistantReply: reply,
      });
      threadId = saved.threadId;
    } catch {
      // Soft-fail history — still return the reply.
    }

    return {
      enabled: true,
      locale: replyLocale,
      reply,
      threadId,
    };
  }

  /**
   * Streaming assistant reply (SSE). Events: {delta}… then a final
   * {done:true, threadId, locale}. The app renders tokens as they land.
   */
  @Post('assistant/stream')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  async assistantStream(
    @CurrentUser() actor: AuthUser,
    @Body() dto: AiAssistantDto,
    @Headers('accept-language') acceptLanguage: string | undefined,
    @Res() res: Response,
  ) {
    this.assertAiUser(actor);

    const locale =
      dto.locale ??
      this.ai.resolveLocale(acceptLanguage?.split(',')[0] ?? 'en');
    const replyLocale = this.ai.resolveReplyLocale(dto.message ?? '', locale);

    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no');
    const send = (obj: Record<string, unknown>) => {
      try {
        res.write(`data: ${JSON.stringify(obj)}\n\n`);
      } catch {
        // Client went away mid-stream.
      }
    };

    const status = await this.ai.statusAsync();
    if (!status.enabled) {
      send({
        enabled: false,
        locale: replyLocale,
        reply: this.ai.disabledCopy(replyLocale),
        done: true,
        threadId: dto.threadId ?? null,
      });
      res.end();
      return;
    }

    const message = dto.message.trim();
    const attachment = dto.attachment
      ? parseAiAttachment(dto.attachment)
      : undefined;
    if (!message && !attachment) {
      send({ error: 'Message is empty', done: true });
      res.end();
      return;
    }

    let full = '';
    try {
      for await (const delta of this.ai.streamComplete({
        userId: actor.userId,
        locale,
        userMessage: message,
        history: dto.history,
        purpose: 'assistant',
        attachment,
      })) {
        full += delta;
        send({ delta });
      }
    } catch {
      if (!full) {
        send({ error: 'AI unavailable — try again', done: true });
        res.end();
        return;
      }
      // Partial reply already streamed — finish gracefully below.
    }

    const historyText =
      message ||
      (attachment ? `[${attachment.kind}] ${attachment.filename}` : '');
    let threadId: string | null = dto.threadId ?? null;
    try {
      const saved = await this.history.appendExchange({
        userId: actor.userId,
        threadId: dto.threadId,
        userMessage: historyText,
        assistantReply: full,
      });
      threadId = saved.threadId;
    } catch {
      // Soft-fail history — the streamed reply still counts.
    }

    send({ done: true, threadId, locale: replyLocale });
    res.end();
  }

  @Post('see-text')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  seeText(@CurrentUser() actor: AuthUser, @Body() dto: AiSeeTextDto) {
    this.assertAiUser(actor);
    return this.ai.seeText({
      userId: actor.userId,
      dataBase64: dto.dataBase64,
      mime: dto.mime,
    });
  }

  @Post('transcribe')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  transcribe(@CurrentUser() actor: AuthUser, @Body() dto: AiTranscribeDto) {
    this.assertAiUser(actor);
    return this.ai.transcribe({
      userId: actor.userId,
      dataBase64: dto.dataBase64,
      mime: dto.mime,
    });
  }

  /** WeChat-style translate for chat / OBIC AI bubbles (JWT). */
  @Post('translate')
  @HttpCode(200)
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  async translate(@CurrentUser() actor: AuthUser, @Body() dto: AiTranslateDto) {
    this.assertAiUser(actor);

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
      userId: actor.userId,
      text: dto.text,
      targetLocale,
      messageId: dto.messageId,
    });

    return {
      enabled: true,
      targetLocale: result.targetLocale,
      translation: result.translation,
      cached: result.cached,
    };
  }
}
