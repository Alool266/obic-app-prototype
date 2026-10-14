// Made by Dr Ali
// The phone registers its Apple or Google push token with our server.

import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { PushService } from './push.service';

class RegisterPushDto {
  @IsIn(['ios', 'android', 'ios_voip'])
  platform!: 'ios' | 'android' | 'ios_voip';

  @IsString()
  @MinLength(8)
  @MaxLength(512)
  token!: string;
}

@Controller('push')
@UseGuards(JwtAuthGuard)
export class PushController {
  constructor(private readonly push: PushService) {}

  @Post('devices')
  register(@CurrentUser() actor: AuthUser, @Body() dto: RegisterPushDto) {
    return this.push.register(actor.userId, dto.platform, dto.token);
  }
}
