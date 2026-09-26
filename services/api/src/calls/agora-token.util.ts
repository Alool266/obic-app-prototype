// Made by Dr Ali
// Thin wrapper around agora-token — keeps RTC mint logic unit-testable.

import { RtcRole, RtcTokenBuilder } from 'agora-token';

export type MintRtcTokenInput = {
  appId: string;
  appCertificate: string;
  channelName: string;
  uid: number;
  ttlSeconds: number;
};

/**
 * Mint an RTC token (AccessToken2).
 *
 * IMPORTANT: agora-token's RtcTokenBuilder2 expects tokenExpire / privilegeExpire
 * as **relative seconds from now** (e.g. 3600), NOT absolute Unix timestamps.
 * Passing `Date.now()/1000 + ttl` overflows signed int32 when Agora adds
 * issueTs + privilege → join fails with invalid/expired token (UI used to
 * mis-label that as a generic network error).
 */
export function mintRtcToken(input: MintRtcTokenInput): {
  token: string;
  expiresAt: string;
} {
  const ttl = Math.max(60, Math.floor(input.ttlSeconds));
  const token = RtcTokenBuilder.buildTokenWithUid(
    input.appId,
    input.appCertificate,
    input.channelName,
    input.uid,
    RtcRole.PUBLISHER,
    ttl,
    ttl,
  );
  const expiresAt = new Date(Date.now() + ttl * 1000).toISOString();
  return { token, expiresAt };
}

/** Stable Agora uid (1..2^31-1) from OBIC user UUID — never 0. */
export function agoraUidFromUserId(userId: string): number {
  let h = 0;
  for (let i = 0; i < userId.length; i++) {
    h = (Math.imul(31, h) + userId.charCodeAt(i)) | 0;
  }
  const u = (h >>> 0) % 2_147_483_647;
  return u === 0 ? 1 : u;
}
