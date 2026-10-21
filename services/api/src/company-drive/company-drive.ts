// Made by Dr Ali
// Company drive names, types, and size. Files are not public links.

export const DRIVE_FOLDER_LIMIT = 40;
export const DRIVE_FILES_PER_FOLDER = 80;
export const DRIVE_FILE_BYTES = 8 * 1024 * 1024;
export const DRIVE_FOLDER_NAME_MAX = 40;
export const DRIVE_FILE_NAME_MAX = 80;

const DRIVE_EXTENSIONS = [
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'txt',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'zip',
] as const;

export type DriveExtension = (typeof DRIVE_EXTENSIONS)[number];

const ALLOWED = new Set<string>(DRIVE_EXTENSIONS);

export function normalizeDriveFolderName(value: string): string {
  const name = value.trim().replace(/\s+/g, ' ');
  if (!name || name.length > DRIVE_FOLDER_NAME_MAX) throw new Error('DRIVE_FOLDER_NAME');
  return name;
}

export function driveFolderKey(name: string): string {
  const key = name.toLocaleLowerCase();
  if (!key || key.length > DRIVE_FOLDER_NAME_MAX) throw new Error('DRIVE_FOLDER_NAME');
  return key;
}

export function driveFileParts(original: string): { name: string; ext: DriveExtension; key: string } {
  const base = original.replace(/\\/g, '/').split('/').pop() ?? '';
  const name = base.trim().replace(/\s+/g, ' ');
  const dot = name.lastIndexOf('.');
  if (!name || name.length > DRIVE_FILE_NAME_MAX || dot <= 0 || dot === name.length - 1) {
    throw new Error(!name || name.length > DRIVE_FILE_NAME_MAX ? 'DRIVE_FILE_NAME' : 'DRIVE_TYPE');
  }
  const ext = name.slice(dot + 1).toLocaleLowerCase();
  if (!ALLOWED.has(ext)) throw new Error('DRIVE_TYPE');
  const key = name.toLocaleLowerCase();
  if (key.length > DRIVE_FILE_NAME_MAX) throw new Error('DRIVE_FILE_NAME');
  return { name, ext: ext as DriveExtension, key };
}

export function assertDriveBytes(size: number): void {
  if (!Number.isInteger(size) || size < 1 || size > DRIVE_FILE_BYTES) {
    throw new Error('DRIVE_SIZE');
  }
}

export function driveMime(ext: DriveExtension): string {
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'txt':
      return 'text/plain';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'zip':
      return 'application/zip';
    default: {
      const unexpected: never = ext;
      return unexpected;
    }
  }
}

export function driveContentDisposition(name: string): string {
  const cleaned = name.replace(/[\r\n"]/g, '').trim() || 'file';
  const ascii = cleaned.replace(/[^\x20-\x7E]/g, '_').trim() || 'file';
  return `attachment; filename="${ascii}"; filename*=UTF-8''${encodeURIComponent(cleaned)}`;
}
