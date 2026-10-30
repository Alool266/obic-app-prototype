// Made by Dr Ali
// Auth HTTP surface — register / login / refresh / logout under /v1/auth.

import { Body, Controller, Get, HttpCode, Post, Req, Res, UseGuards } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { StartEmailVerifyDto } from '../users/dto/start-email-verify.dto';
import { StartPhoneVerifyDto } from '../users/dto/start-phone-verify.dto';
import { AuthService } from './auth.service';
import {
  googleAndroidCallbackHtml,
  googleAndroidIntentLocation,
} from './google-android-callback';
import { LoginDto } from './dto/login.dto';
import { PhoneLoginStartDto } from './dto/phone-login.dto';
import { LogoutDto, RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { SocialSignInDto } from './dto/social-sign-in.dto';
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

  @Post('social')
  @HttpCode(200)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Sign in or sign up with a verified Google or Apple token',
    description:
      'Server verifies the ID token. A verified provider email skips OBIC email OTP. China phone verification is unchanged.',
  })
  social(@Body() dto: SocialSignInDto) {
    return this.authService.socialSignIn(dto);
  }

  /**
   * Android Sign in with Apple returns here (form POST from Apple), then the
   * browser is sent back into the app. The app still calls POST /auth/social
   * so the identity token is verified before any session exists.
   */
  @Post('apple/android-callback')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Android Sign in with Apple browser return (redirect only)',
  })
  appleAndroidCallback(@Req() req: Request, @Res() res: Response): void {
    const params = new URLSearchParams();
    const body = req.body;
    if (body && typeof body === 'object') {
      for (const [key, value] of Object.entries(
        body as Record<string, unknown>,
      )) {
        if (typeof value !== 'string') continue;
        if (!/^[a-zA-Z0-9_]{1,32}$/.test(key)) continue;
        params.append(key, value.slice(0, 20_000));
      }
    }
    const intent =
      `intent://callback?${params.toString()}` +
      '#Intent;package=com.obic.app.obic_mobile;scheme=signinwithapple;end';
    res.redirect(302, intent);
  }

  /**
   * Android Google sign-in returns here from the browser, then the browser is
   * sent back into the app. The app still calls POST /auth/social so the ID
   * token is verified before any session exists.
   * form_post puts the token in the body. A fragment response never reaches
   * the server, so GET serves a page that reads the hash in the browser.
   */
  @Post('google/android-callback')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Android Google browser return (redirect only)',
  })
  googleAndroidCallback(@Req() req: Request, @Res() res: Response): void {
    const body =
      req.body && typeof req.body === 'object'
        ? (req.body as Record<string, unknown>)
        : null;
    res.redirect(302, googleAndroidIntentLocation(body));
  }

  @Get('google/android-callback')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Android Google browser return page (fragment to app)',
  })
  googleAndroidCallbackPage(@Res() res: Response): void {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.status(200).send(googleAndroidCallbackHtml);
  }

  @Post('phone-login/start')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({
    summary: 'WeChat-style sign-in: send SMS code to a phone number',
    description:
      'New numbers create a Customer account; completing /verify-otp signs in and marks the phone verified. Customers only.',
  })
  phoneLoginStart(@Body() dto: PhoneLoginStartDto) {
    return this.authService.startPhoneLogin(dto);
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
    summary: 'Start China mainland phone OTP (logged-in add/verify)',
  })
  startPhoneVerify(
    @CurrentUser() actor: AuthUser,
    @Body() dto: StartPhoneVerifyDto,
  ) {
    return this.authService.startPhoneVerify(actor, dto);
  }

  @Post('email/start')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Start email OTP for logged-in user (China cohort required)',
  })
  startEmailVerify(
    @CurrentUser() actor: AuthUser,
    @Body() dto: StartEmailVerifyDto,
  ) {
    return this.authService.startEmailVerify(actor, dto);
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
