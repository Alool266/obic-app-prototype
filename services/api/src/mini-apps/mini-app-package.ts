// Made by Dr Ali
// Unpack a partner mini-app zip. index.html must sit at the package root.
// Zip-slip, absolute paths, and anything outside the allow-list are rejected.

import { BadRequestException } from '@nestjs/common';
import { unzipSync } from 'fflate';

export const MINI_APP_PACKAGE_MAX_BYTES = 8 * 1024 * 1024;

const PACKAGE_EXTS = [
  'html',
  'css',
  'js',
  'json',
  'svg',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
  'woff',
  'woff2',
  'mp3',
  'wav',
  'ogg',
] as const;

export type PackageExt = (typeof PACKAGE_EXTS)[number];

export type PackageFile = {
  path: string;
  mime: string;
  data: Buffer;
};

export function hostedPackageIndexPath(id: string): string {
  return `/v1/mini-apps/${id}/files/index.html`;
}

export function packageMime(ext: PackageExt): string {
  switch (ext) {
    case 'html':
      return 'text/html; charset=utf-8';
    case 'css':
      return 'text/css; charset=utf-8';
    case 'js':
      return 'text/javascript; charset=utf-8';
    case 'json':
      return 'application/json; charset=utf-8';
    case 'svg':
      return 'image/svg+xml';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'woff':
      return 'font/woff';
    case 'woff2':
      return 'font/woff2';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
      return 'audio/ogg';
    default: {
      const _exhaustive: never = ext;
      return _exhaustive;
    }
  }
}

function asPackageExt(ext: string): PackageExt | null {
  switch (ext) {
    case 'html':
    case 'css':
    case 'js':
    case 'json':
    case 'svg':
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'webp':
    case 'gif':
    case 'woff':
    case 'woff2':
    case 'mp3':
    case 'wav':
    case 'ogg':
      return ext as PackageExt;
    default:
      return null;
  }
}

/** Relative package path, or null when the name is unsafe. */
export function safePackagePath(raw: string): string | null {
  if (!raw || raw.includes('\0')) return null;
  let name = raw.replace(/\\/g, '/');
  if (name.startsWith('/') || name.startsWith('//')) return null;
  if (/^[a-zA-Z]:/.test(name)) return null;
  while (name.startsWith('./')) name = name.slice(2);
  if (!name || name.endsWith('/')) return null;
  if (name.length > 512) return null;
  const parts = name.split('/');
  if (parts.some((part) => part === '' || part === '.' || part === '..')) {
    return null;
  }
  return parts.join('/');
}

function ignoredZipNoise(path: string): boolean {
  return (
    path === '.DS_Store' ||
    path.endsWith('/.DS_Store') ||
    path.startsWith('__MACOSX/')
  );
}

export function validatePackageFiles(
  entries: { path: string; data: Uint8Array }[],
  maxBytes = MINI_APP_PACKAGE_MAX_BYTES,
): PackageFile[] {
  const out: PackageFile[] = [];
  const seen = new Set<string>();
  let total = 0;
  for (const entry of entries) {
    const path = safePackagePath(entry.path);
    if (!path) {
      throw new BadRequestException('Package path is not allowed');
    }
    if (ignoredZipNoise(path)) continue;
    const base = path.split('/').pop() ?? path;
    const dot = base.lastIndexOf('.');
    const ext = dot >= 0 ? asPackageExt(base.slice(dot + 1).toLowerCase()) : null;
    if (!ext) {
      throw new BadRequestException(`File type not allowed: ${path}`);
    }
    if (seen.has(path)) {
      throw new BadRequestException(`Duplicate file: ${path}`);
    }
    seen.add(path);
    total += entry.data.byteLength;
    if (entry.data.byteLength > maxBytes || total > maxBytes) {
      throw new BadRequestException('Package is larger than 8 MB uncompressed');
    }
    out.push({
      path,
      mime: packageMime(ext),
      data: Buffer.from(entry.data),
    });
  }
  if (!seen.has('index.html')) {
    throw new BadRequestException('Package must include index.html at the root');
  }
  return out;
}

export function unpackMiniAppZip(
  zip: Buffer,
  maxBytes = MINI_APP_PACKAGE_MAX_BYTES,
): PackageFile[] {
  if (!zip?.length) {
    throw new BadRequestException('Package file is empty');
  }
  if (zip.length > maxBytes) {
    throw new BadRequestException('Package zip is larger than 8 MB');
  }
  let claimed = 0;
  let unzipped: Record<string, Uint8Array>;
  try {
    unzipped = unzipSync(new Uint8Array(zip), {
      filter(file) {
        const name = file.name.replace(/\\/g, '/');
        if (name.endsWith('/')) return false;
        if (ignoredZipNoise(name.replace(/^\//, ''))) return false;
        const declared = file.originalSize || 0;
        if (declared > maxBytes) {
          throw new BadRequestException('Package is larger than 8 MB uncompressed');
        }
        if (declared === 0 && file.size > 0) {
          throw new BadRequestException('Package file size is not trusted');
        }
        if (declared > 0 && file.size > 0 && declared / file.size > 100) {
          throw new BadRequestException('Package expands too far');
        }
        claimed += declared;
        if (claimed > maxBytes) {
          throw new BadRequestException('Package is larger than 8 MB uncompressed');
        }
        return true;
      },
    });
  } catch (error) {
    if (error instanceof BadRequestException) throw error;
    throw new BadRequestException('Package zip could not be read');
  }
  const entries = Object.entries(unzipped).map(([path, data]) => ({ path, data }));
  return validatePackageFiles(entries, maxBytes);
}

/** File path after `/files/` or `/preview/:ticket/`. Null when it is unsafe. */
export function packageFilePathFromUrl(originalUrl: string, marker: string): string | null {
  const pathOnly = (originalUrl.split('?')[0] ?? '').split('#')[0] ?? '';
  let decoded = pathOnly;
  try {
    decoded = decodeURIComponent(pathOnly);
  } catch {
    return null;
  }
  const idx = decoded.indexOf(marker);
  if (idx < 0) return null;
  return safePackagePath(decoded.slice(idx + marker.length));
}
