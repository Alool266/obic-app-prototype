// Made by Dr Ali

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiModule } from '../ai/ai.module';
import { AuditLog } from '../chat/audit-log.entity';
import { ChatModule } from '../chat/chat.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OrdersModule } from '../orders/orders.module';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { AdminController } from './admin.controller';
import { AdminTotpController } from './admin-totp.controller';
import { AdminTotpService } from './admin-totp.service';
import { AdminService } from './admin.service';
import { TotpModule } from '../auth/totp/totp.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Order, AuditLog]),
    TotpModule,
    ChatModule,
    OrdersModule,
    NotificationsModule,
    AiModule,
  ],
  controllers: [AdminController, AdminTotpController],
  providers: [AdminService, AdminTotpService],
})
export class AdminModule {}
