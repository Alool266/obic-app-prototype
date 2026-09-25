// Made by Dr Ali

import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { RefreshSession } from './refresh-session.entity';
import { TotpModule } from './totp/totp.module';
import { MailSenderService } from './mail-sender.service';
import { SmsSenderService } from './sms-sender.service';
import { VerificationChallenge } from './verification-challenge.entity';
import { VerificationService } from './verification.service';
import { User } from '../users/user.entity';

@Module({
  imports: [
    UsersModule,
    TotpModule,
    TypeOrmModule.forFeature([RefreshSession, VerificationChallenge, User]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.get<string>('JWT_SECRET');
        if (!secret) {
          throw new Error('JWT_SECRET is required');
        }
        return {
          secret,
          signOptions: {
            // 15 minutes — short-lived access token (architecture baseline).
            expiresIn: 60 * 15,
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    MailSenderService,
    SmsSenderService,
    VerificationService,
  ],
  exports: [AuthService, JwtModule, VerificationService],
})
export class AuthModule {}
