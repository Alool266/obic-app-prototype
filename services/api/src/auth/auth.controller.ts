// Made by Dr Ali
// Auth HTTP surface — register / login / refresh / logout under /v1/auth.

import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { StartPhoneVerifyDto } from '../users/dto/start-phone-verify.dto';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { LogoutDto, RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { TotpVerifyDto } from './dto/totp-verify.dto';
import { ResendOtpDto, VerifyOtpDto } from './dto/verify-otp.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /** Stricter limits on credential endpoints (brute-force mitigation). */
  @Post('register')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Login with email or phone + password',
    description:
      'Returns access + refresh tokens. Never send real passwords in docs.',
  })
  @ApiOkResponse({
    description: 'accessToken, refreshToken, user (no password)',
  })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('verify-otp')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({ summary: 'Complete register/login after email or phone OTP' })
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp({
      verifySession: dto.verifySession,
      code: dto.code,
    });
  }

  @Post('resend-otp')
  @HttpCode(200)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @ApiOperation({ summary: 'Resend verification OTP (60s cooldown)' })
  resendOtp(@Body() dto: ResendOtpDto) {
    return this.authService.resendOtp(dto.verifySession);
  }

  @Post('phone/start')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Start China mainland phone SMS OTP (logged-in add/verify)',
  })
  startPhoneVerify(
    @CurrentUser() actor: AuthUser,
    @Body() dto: StartPhoneVerifyDto,
  ) {
    return this.authService.startPhoneVerify(actor, dto);
  }

  @Post('totp/verify')
  @HttpCode(200)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({ summary: 'Complete SuperAdmin login after TOTP code' })
  verifyTotp(@Body() dto: TotpVerifyDto) {
    return this.authService.verifyTotpLogin(dto);
  }

  @Post('refresh')
  @HttpCode(200)
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @HttpCode(200)
  logout(@Body() dto: LogoutDto) {
    return this.authService.logout(dto.refreshToken);
  }
}
