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

export function mintRtcToken(input: MintRtcTokenInput): {
  token: string;
  expiresAt: string;
} {
  const expire = Math.floor(Date.now() / 1000) + input.ttlSeconds;
  const token = RtcTokenBuilder.buildTokenWithUid(
    input.appId,
    input.appCertificate,
    input.channelName,
    input.uid,
    RtcRole.PUBLISHER,
    expire,
    expire,
  );
  return { token, expiresAt: new Date(expire * 1000).toISOString() };
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
