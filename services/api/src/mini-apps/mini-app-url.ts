// Made by Dr Ali
// HTTPS page URLs for the in-app mini-app engine. No credentials in the URL.

import { BadRequestException } from '@nestjs/common';

export function assertHttpsPageUrl(raw: string): string {
  const trimmed = (raw ?? '').trim();
  if (!trimmed || trimmed.length > 2048) {
    throw new BadRequestException('Page address must be an HTTPS URL');
  }
  let uri: URL;
  try {
    uri = new URL(trimmed);
  } catch {
    throw new BadRequestException('Page address must be an HTTPS URL');
  }
  if (uri.protocol !== 'https:') {
    throw new BadRequestException('Page address must use HTTPS');
  }
  if (uri.username || uri.password) {
    throw new BadRequestException('Page address must not include credentials');
  }
  if (!uri.hostname) {
    throw new BadRequestException('Page address must include a host');
  }
  return trimmed;
}

/**
 * Icon is optional. HTTPS URLs are allowed. Uploaded images may be a
 * `/uploads/...` path or an http(s) URL whose path is under `/uploads/`.
 */
export function normalizeIconUrl(raw: string | null | undefined): string | null {
  if (raw == null) return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (trimmed.length > 1024) {
    throw new BadRequestException('Icon URL is too long');
  }
  if (
    trimmed.startsWith('/uploads/') &&
    !trimmed.includes('..') &&
    !trimmed.includes('\\') &&
    !trimmed.includes('://')
  ) {
    return trimmed;
  }
  let uri: URL;
  try {
    uri = new URL(trimmed);
  } catch {
    throw new BadRequestException('Icon must be an HTTPS URL or an uploaded image');
  }
  if (uri.username || uri.password) {
    throw new BadRequestException('Icon URL must not include credentials');
  }
  const uploadPath = uri.pathname.startsWith('/uploads/');
  if (uri.protocol === 'https:') return trimmed;
  if (uploadPath && uri.protocol === 'http:') return trimmed;
  throw new BadRequestException('Icon must be an HTTPS URL or an uploaded image');
}
