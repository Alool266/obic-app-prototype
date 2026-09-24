// Made by Dr Ali
// Authenticated request principal (from JWT). Never trust client-sent userId.

/** Class (not interface) so Nest decorator metadata works under isolatedModules. */
export class AuthUser {
  constructor(
    /** Subject — user UUID */
    public readonly userId: string,
    /** Session id for revoke / refresh rotation */
    public readonly sessionId: string,
    /** Role claim — treat as hint until DB re-check on sensitive actions */
    public readonly role: string,
  ) {}
}
