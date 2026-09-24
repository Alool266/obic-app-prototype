// Made by Dr Ali
// Optional JWT — guests browse; signed-in users get likedByMe flags.

import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    const req = context.switchToHttp().getRequest<{ headers?: { authorization?: string } }>();
    const auth = req.headers?.authorization;
    if (!auth?.startsWith('Bearer ')) {
      return true;
    }
    return super.canActivate(context);
  }

  handleRequest<TUser>(err: Error | null, user: TUser): TUser | null {
    if (err) {
      // Soft-fail for optional auth (expired token → treat as guest).
      if (err instanceof UnauthorizedException) return null;
      throw err;
    }
    return user ?? null;
  }
}
