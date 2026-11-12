// Pure auth helpers for the deployed dashboard. No Firebase import here, so
// the allowlist rule stays unit-testable without credentials.

/// Parses the comma-separated ADMIN_EMAILS value into a lowercase set.
export function parseAdminEmails(value) {
  return new Set(
    String(value ?? '')
      .split(',')
      .map((entry) => entry.trim().toLowerCase())
      .filter(Boolean),
  );
}

/// A verified Google account whose email is on the allowlist. Anything else
/// is rejected before a privileged endpoint runs.
export function isAllowedAdmin(decoded, allowedEmails) {
  if (!decoded || typeof decoded !== 'object') return false;
  if (decoded.email_verified !== true) return false;
  if (typeof decoded.email !== 'string') return false;
  return allowedEmails.has(decoded.email.trim().toLowerCase());
}
