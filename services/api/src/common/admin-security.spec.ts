// Made by Dr Ali
// Unit tests for admin IP allowlist + CORS helpers.

import {
  ipMatchesAllowlist,
  ipv4ToInt,
  normalizeIp,
} from './admin-security';

describe('admin-security IP allowlist', () => {
  it('allows all when list empty', () => {
    expect(ipMatchesAllowlist('1.2.3.4', [])).toBe(true);
  });

  it('matches exact IPv4', () => {
    expect(ipMatchesAllowlist('203.0.113.10', ['203.0.113.10'])).toBe(true);
    expect(ipMatchesAllowlist('203.0.113.11', ['203.0.113.10'])).toBe(false);
  });

  it('matches IPv4 CIDR', () => {
    expect(ipMatchesAllowlist('10.1.2.3', ['10.0.0.0/8'])).toBe(true);
    expect(ipMatchesAllowlist('11.0.0.1', ['10.0.0.0/8'])).toBe(false);
    expect(ipMatchesAllowlist('192.168.1.50', ['192.168.1.0/24'])).toBe(true);
  });

  it('normalizes ::ffff and localhost', () => {
    expect(normalizeIp('::ffff:127.0.0.1')).toBe('127.0.0.1');
    expect(normalizeIp('::1')).toBe('127.0.0.1');
    expect(ipv4ToInt('127.0.0.1')).toBe(0x7f000001);
  });
});
