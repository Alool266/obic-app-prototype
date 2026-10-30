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
import { ApprovalsModule } from './approvals/approvals.module';
import { AttendanceModule } from './attendance/attendance.module';
import { ReportsModule } from './reports/reports.module';
import { OfficeFormsModule } from './office-forms/office-forms.module';
import { CollectionFormsModule } from './collection-forms/collection-forms.module';
import { MeetingRoomsModule } from './meeting-rooms/meeting-rooms.module';
import { RosterModule } from './roster/roster.module';
import { PayslipsModule } from './payslips/payslips.module';
import { CompanyContactsModule } from './company-contacts/company-contacts.module';
import { CompanyTagsModule } from './company-tags/company-tags.module';
import { CompanyGroupsModule } from './company-groups/company-groups.module';
import { CompanyWelcomesModule } from './company-welcomes/company-welcomes.module';
import { QuickRepliesModule } from './quick-replies/quick-replies.module';
import { CompanyHandoversModule } from './company-handovers/company-handovers.module';
import { CompanyDriveModule } from './company-drive/company-drive.module';
import { CompanyDocumentsModule } from './company-documents/company-documents.module';
import { CompanySpreadsheetsModule } from './company-spreadsheets/company-spreadsheets.module';
import { CompanyCalendarModule } from './company-calendar/company-calendar.module';
import { CompanyMailModule } from './company-mail/company-mail.module';
import { CompanyMeetingsModule } from './company-meetings/company-meetings.module';
import { CompanyFileAnswersModule } from './company-file-answers/company-file-answers.module';
import { CompanyAppsModule } from './company-apps/company-apps.module';
import { loadOptionalAiEnvFiles } from './ai/ai-env.loader';
import { AiModule } from './ai/ai.module';
import { AuthModule } from './auth/auth.module';
import { loadOptionalAgoraEnvFiles } from './calls/agora-env.loader';
import { CallsModule } from './calls/calls.module';
import { ChannelsModule } from './channels/channels.module';
import { ChatModule } from './chat/chat.module';
import { CommonModule } from './common/common.module';
import { DirectoryModule } from './directory/directory.module';
import { AdminIpAllowlistMiddleware } from './common/middleware/admin-ip-allowlist.middleware';
import { FriendsModule } from './friends/friends.module';
import { HealthModule } from './health/health.module';
import { MiniAppsModule } from './mini-apps/mini-apps.module';
import { UserOfficeModule } from './user-office/user-office.module';
import { ModerationModule } from './moderation/moderation.module';
import { MomentsModule } from './moments/moments.module';
import { loadOptionalApnsEnvFiles } from './notifications/apns-env.loader';
import { NotificationsModule } from './notifications/notifications.module';
import { HubContentModule } from './hub-content/hub-content.module';
import { MarketplaceModule } from './marketplace/marketplace.module';
import { OffersModule } from './offers/offers.module';
import { OrdersModule } from './orders/orders.module';
import { RealtimeModule } from './realtime/realtime.module';
import { RedisModule } from './redis/redis.module';
import { RedisService } from './redis/redis.service';
import { PricesModule } from './prices/prices.module';
import { RegistrationModule } from './registration/registration.module';
import { VipModule } from './vip/vip.module';
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
        join(homedir(), '.config', 'obic', 'fcm.env'),
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
    PricesModule,
    RegistrationModule,
    VipModule,
    OffersModule,
    MarketplaceModule,
    HubContentModule,
    OrdersModule,
    ChatModule,
    CallsModule,
    ChannelsModule,
    AiModule,
    MomentsModule,
    ModerationModule,
    MiniAppsModule,
    UserOfficeModule,
    NotificationsModule,
    FriendsModule,
    UploadsModule,
    DirectoryModule,
    ApprovalsModule,
    AttendanceModule,
    ReportsModule,
    OfficeFormsModule,
    CollectionFormsModule,
    MeetingRoomsModule,
    RosterModule,
    PayslipsModule,
    CompanyContactsModule,
    CompanyTagsModule,
    CompanyGroupsModule,
    CompanyWelcomesModule,
    QuickRepliesModule,
    CompanyHandoversModule,
    CompanyDriveModule,
    CompanyDocumentsModule,
    CompanySpreadsheetsModule,
    CompanyCalendarModule,
    CompanyMailModule,
    CompanyMeetingsModule,
    CompanyFileAnswersModule,
    CompanyAppsModule,
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
