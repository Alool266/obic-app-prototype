// Made by Dr Ali
// JWT access-token payload — role is a UI hint; re-check DB for sensitive actions.

import { UserRole } from '../common/enums/user-role.enum';

/** Named ObicJwtPayload to avoid clashing with @nestjs/jwt JwtPayload. */
export interface ObicJwtPayload {
  sub: string;
  sid: string;
  role: UserRole;
}
