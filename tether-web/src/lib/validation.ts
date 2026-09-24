const NOTICE_TAGS = new Set(['ANNOUNCEMENT', 'CLASS_UPDATE', 'REMINDER', 'EVENT']);

export function isValidNoticeTag(tag: string) {
  return NOTICE_TAGS.has(tag);
}

export function isValidHexColor(value: string) {
  return /^#[0-9a-fA-F]{6}$/.test(value);
}

export function isValidEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export function isLikelyPhone(value: string) {
  return /^[0-9+\-() ]{7,20}$/.test(value);
}

export function isValidHttpUrl(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

export function isValidTimezone(value: string) {
  try {
    Intl.DateTimeFormat(undefined, { timeZone: value });
    return true;
  } catch {
    return false;
  }
}
