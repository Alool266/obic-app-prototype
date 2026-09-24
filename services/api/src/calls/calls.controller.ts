// Made by Dr Ali
// /v1/calls — create/ring + scoped Agora RTC tokens (JWT; participant ACL).

import {
  Body,
  Controller,
  Get,
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
import { CallsService } from './calls.service';
import { CreateCallDto } from './dto/calls.dto';

@Controller('calls')
@UseGuards(JwtAuthGuard)
export class CallsController {
  constructor(private readonly calls: CallsService) {}

  /** Whether Agora keys are loaded (never returns secrets). */
  @Get('status')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  status() {
    return this.calls.status();
  }

  /** Create channel + ring peers; returns join payload for the caller. */
  @Post()
  @HttpCode(201)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateCallDto) {
    return this.calls.createCall(actor, dto);
  }

  /** Mint / refresh RTC token for an existing call (callee accept). */
  @Post(':id/token')
  @HttpCode(200)
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  postToken(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.calls.mintToken(actor, id);
  }

  @Get(':id/token')
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  getToken(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.calls.mintToken(actor, id);
  }

  @Post(':id/end')
  @HttpCode(200)
  @Throttle({ default: { limit: 40, ttl: 60_000 } })
  end(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.calls.endCall(actor, id);
  }
}
