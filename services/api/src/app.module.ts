// Made by Dr Ali
// Root module — wires config, Postgres, Redis, throttle, and feature modules.

import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ThrottlerStorageRedisService } from '@nest-lab/throttler-storage-redis';
import { TypeOrmModule } from '@nestjs/typeorm';
import { homedir } from 'os';
import { join } from 'path';
import { AdminModule } from './admin/admin.module';
import { loadOptionalAiEnvFiles } from './ai/ai-env.loader';
import { AiModule } from './ai/ai.module';
import { AuthModule } from './auth/auth.module';
import { loadOptionalAgoraEnvFiles } from './calls/agora-env.loader';
import { CallsModule } from './calls/calls.module';
import { ChatModule } from './chat/chat.module';
import { CommonModule } from './common/common.module';
import { AdminIpAllowlistMiddleware } from './common/middleware/admin-ip-allowlist.middleware';
import { FriendsModule } from './friends/friends.module';
import { HealthModule } from './health/health.module';
import { ModerationModule } from './moderation/moderation.module';
import { MomentsModule } from './moments/moments.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OffersModule } from './offers/offers.module';
import { OrdersModule } from './orders/orders.module';
import { RealtimeModule } from './realtime/realtime.module';
import { RedisModule } from './redis/redis.module';
import { RedisService } from './redis/redis.service';
import { ServicesModule } from './services/services.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';

// Local/trial AI + Agora keys (~/.config/obic/*.env) before ConfigModule.
loadOptionalAiEnvFiles();
loadOptionalAgoraEnvFiles();

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      // Prefer process env in prod; local `.env` at repo root or services/api.
      // ai.env + ~/.config/obic/ai.env: free-tier keys without committing secrets.
      envFilePath: [
        '.env',
        'ai.env',
        'agora.env',
        join(homedir(), '.config', 'obic', 'ai.env'),
        join(homedir(), '.config', 'obic', 'agora.env'),
        '../../.env',
      ],
    }),
    RedisModule,
    // Global baseline; auth routes tighten further with @Throttle.
    // When Redis is up, rate-limit counters are shared across API instances.
    ThrottlerModule.forRootAsync({
      imports: [RedisModule],
      inject: [RedisService],
      useFactory: (redis: RedisService) => {
        const client = redis.getClient();
        return {
          throttlers: [
            {
              ttl: 60_000,
              limit: 120,
            },
          ],
          ...(client
            ? { storage: new ThrottlerStorageRedisService(client) }
            : {}),
        };
      },
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        url: config.get<string>('DATABASE_URL'),
        autoLoadEntities: true,
        // Prefer migrations; allow local override only via env flag.
        synchronize: config.get<string>('TYPEORM_SYNCHRONIZE') === 'true',
        // Render / managed Postgres often require TLS (trial + production).
        ssl:
          config.get<string>('DATABASE_SSL') === 'true'
            ? { rejectUnauthorized: false }
            : undefined,
        retryAttempts: 3,
      }),
    }),
    CommonModule,
    HealthModule,
    UsersModule,
    AuthModule,
    ServicesModule,
    OffersModule,
    OrdersModule,
    ChatModule,
    CallsModule,
    AiModule,
    MomentsModule,
    ModerationModule,
    NotificationsModule,
    FriendsModule,
    UploadsModule,
    AdminModule,
    RealtimeModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(AdminIpAllowlistMiddleware).forRoutes('admin');
  }
}
