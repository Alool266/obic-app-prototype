// Made by Dr Ali
// /v1/ai — OBIC AI assistant + status + history (JWT). Keys never leave the server.

import {
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
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { AiHistoryService } from './ai-history.service';
import { AiService } from './ai.service';
import { AiAssistantDto, AiTranslateDto } from './dto/ai.dto';

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

    const reply = await this.ai.complete({
      userId: actor.userId,
      locale,
      userMessage: dto.message,
      history: dto.history,
      purpose: 'assistant',
    });

    let threadId: string | null = dto.threadId ?? null;
    try {
      const saved = await this.history.appendExchange({
        userId: actor.userId,
        threadId: dto.threadId,
        userMessage: dto.message,
        assistantReply: reply,
      });
      threadId = saved.threadId;
    } catch {
      // Soft-fail history — still return the reply.
    }

    return {
      enabled: true,
      locale,
      reply,
      threadId,
    };
  }

  /** WeChat-style translate for chat / OBIC AI bubbles (JWT). */
  @Post('translate')
  @HttpCode(200)
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  async translate(
    @CurrentUser() actor: AuthUser,
    @Body() dto: AiTranslateDto,
  ) {
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
