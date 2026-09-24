// Made by Dr Ali
// Global Redis — optional. Connects at factory time so Throttler can share the client.

import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { RedisService } from './redis.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: RedisService,
      inject: [ConfigService],
      useFactory: async (config: ConfigService) => {
        const redis = new RedisService(config);
        await redis.connect();
        return redis;
      },
    },
  ],
  exports: [RedisService],
})
export class RedisModule {}
