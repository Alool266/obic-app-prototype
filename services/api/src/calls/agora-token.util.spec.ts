// Made by Dr Ali — mintRtcToken must use relative TTL (AccessToken2).

import { RtcRole, RtcTokenBuilder } from 'agora-token';
import { AccessToken2 } from 'agora-token/src/AccessToken2';
import { agoraUidFromUserId, mintRtcToken } from './agora-token.util';

describe('mintRtcToken', () => {
  // Hex-shaped placeholders (agora-token rejects non-hex junk).
  const appId = '970CA35de60c44645bbae8a215061b33';
  const appCertificate = '5Cfd2fd1755d40ecb72977518be15d3b';

  it('stores relative TTL (not absolute Unix) so issueTs+expire fits int32', () => {
    const ttl = 3600;
    const { token, expiresAt } = mintRtcToken({
      appId,
      appCertificate,
      channelName: 'obic_test_channel',
      uid: 42,
      ttlSeconds: ttl,
    });
    expect(token.startsWith('007')).toBe(true);

    const at = new AccessToken2('', '', 0, 0);
    at.from_string(token);
    expect(at.expire).toBe(ttl);
    // Privileges must also be relative — absolute ts overflows signed int32
    // when Agora validates issueTs + privilege.
    const rtc = at.services[0] as { __privileges: Record<number, number> };
    expect(rtc.__privileges[1]).toBe(ttl);

    const expMs = Date.parse(expiresAt);
    expect(expMs).toBeGreaterThan(Date.now() + (ttl - 30) * 1000);
    expect(expMs).toBeLessThan(Date.now() + (ttl + 30) * 1000);
  });

  it('matches RtcTokenBuilder sample usage (relative seconds)', () => {
    const direct = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      'obic_ch',
      99,
      RtcRole.PUBLISHER,
      600,
      600,
    );
    const via = mintRtcToken({
      appId,
      appCertificate,
      channelName: 'obic_ch',
      uid: 99,
      ttlSeconds: 600,
    }).token;
    const a = new AccessToken2('', '', 0, 0);
    const b = new AccessToken2('', '', 0, 0);
    a.from_string(direct);
    b.from_string(via);
    expect(a.expire).toBe(600);
    expect(b.expire).toBe(600);
  });

  it('agoraUidFromUserId never returns 0', () => {
    expect(agoraUidFromUserId('00000000-0000-0000-0000-000000000000')).toBeGreaterThan(
      0,
    );
    expect(agoraUidFromUserId('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')).toBeGreaterThan(
      0,
    );
  });
});
