// Made by Dr Ali
// Authenticated Socket.IO channel — JWT on connect, one room per user.

import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ObicJwtPayload } from '../auth/jwt-payload.interface';
import { RT_READY } from './realtime.events';
import { RealtimeService } from './realtime.service';

@WebSocketGateway({
  namespace: '/realtime',
  cors: { origin: true, credentials: true },
  // Prefer WS; polling fallback helps some proxies.
  transports: ['websocket', 'polling'],
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly realtime: RealtimeService,
  ) {}

  afterInit() {
    this.realtime.bind({
      emitToUsers: (userIds, event, payload) =>
        this.emitToUsers(userIds, event, payload),
    });
    this.logger.log('Realtime gateway ready (namespace /realtime)');
  }

  async handleConnection(client: Socket) {
    try {
      const token = this.extractToken(client);
      if (!token) {
        client.disconnect(true);
        return;
      }
      const payload = await this.jwt.verifyAsync<ObicJwtPayload>(token);
      if (!payload?.sub) {
        client.disconnect(true);
        return;
      }
      const userId = payload.sub;
      client.data.userId = userId;
      await client.join(this.userRoom(userId));
      client.emit(RT_READY, { ok: true, userId });
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data?.userId as string | undefined;
    if (userId) {
      this.logger.debug(`Realtime disconnect user=${userId}`);
    }
  }

  emitToUsers(userIds: string[], event: string, payload: unknown) {
    if (!this.server) return;
    for (const id of new Set(userIds.filter(Boolean))) {
      this.server.to(this.userRoom(id)).emit(event, payload);
    }
  }

  private userRoom(userId: string) {
    return `user:${userId}`;
  }

  private extractToken(client: Socket): string | null {
    const auth = client.handshake.auth as { token?: unknown } | undefined;
    if (typeof auth?.token === 'string' && auth.token.trim()) {
      return auth.token.trim();
    }
    const q = client.handshake.query?.token;
    if (typeof q === 'string' && q.trim()) return q.trim();
    if (Array.isArray(q) && typeof q[0] === 'string' && q[0].trim()) {
      return q[0].trim();
    }
    const header = client.handshake.headers?.authorization;
    if (typeof header === 'string' && header.startsWith('Bearer ')) {
      return header.slice(7).trim() || null;
    }
    return null;
  }
}
