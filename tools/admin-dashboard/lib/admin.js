// Pure helpers for the local admin dashboard. Kept free of Firebase imports so
// the rules can be unit-tested without credentials.

/// Top-level destinations the app accepts in a `route` payload
/// (lib/core/utils/notification_target.dart).
export const ALLOWED_ROUTE_PREFIXES = [
  '/home',
  '/search',
  '/saved',
  '/applications',
  '/profile',
];

/// Splits `items` into arrays of at most `size` entries (FCM multicast and
/// Firestore batches both cap at 500).
export function chunk(items, size) {
  if (!Number.isInteger(size) || size <= 0) {
    throw new Error('size must be a positive integer');
  }
  const out = [];
  for (let index = 0; index < items.length; index += size) {
    out.push(items.slice(index, index + size));
  }
  return out;
}

/// Validates the optional in-app destination of a test message.
///
/// Returns `{ value: null }` when the field is empty, `{ value: route }` when
/// it is a path under a known tab, and `{ error }` otherwise. The app applies
/// the same rule before navigating, so a rejected route would silently open
/// the Notification Center instead of the intended screen.
export function validateRoute(value) {
  if (value === undefined || value === null) return { value: null };
  if (typeof value !== 'string') return { error: 'Route must be a string.' };

  const raw = value.trim();
  if (!raw) return { value: null };
  if (/^[a-z][a-z0-9+.-]*:/i.test(raw) || raw.startsWith('//')) {
    return { error: 'Route must be an absolute in-app path, not a URL.' };
  }

  const path = raw.split('?')[0].split('#')[0];
  if (!path.startsWith('/')) {
    return { error: 'Route must start with "/".' };
  }
  const allowed = ALLOWED_ROUTE_PREFIXES.some(
    (prefix) => path === prefix || path.startsWith(`${prefix}/`),
  );
  if (!allowed) {
    return {
      error:
        'Route must start with one of ' +
        `${ALLOWED_ROUTE_PREFIXES.join(', ')}.`,
    };
  }
  return { value: raw };
}

/// Renders a Firestore Timestamp / Date / ISO string as ISO 8601, or null.
export function toIso(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
  }
  return null;
}

/// Trims a required text field and enforces a maximum length.
export function requireText(value, maxLength) {
  if (typeof value !== 'string') return { error: 'This field is required.' };
  const text = value.trim();
  if (!text) return { error: 'This field is required.' };
  if (text.length > maxLength) {
    return { error: `Keep this under ${maxLength} characters.` };
  }
  return { value: text };
}

/// Converts a multicast/single send result into a small per-recipient summary.
export function summariseSend(responses) {
  return responses.map((entry) =>
    entry.success
      ? { ok: true, messageId: entry.messageId }
      : { ok: false, error: entry.error?.code ?? 'unknown' },
  );
}

/// Firebase Admin returns the full resource name for a sent message
/// (`projects/<project>/messages/<id>`), while Firestore document IDs cannot
/// contain `/`. The app stores the trailing ID (what `RemoteMessage.messageId`
/// carries), so history writes use the same value and merge instead of
/// creating a second document.
export function normaliseMessageId(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  const id = trimmed.split('/').pop();
  return id || null;
}
