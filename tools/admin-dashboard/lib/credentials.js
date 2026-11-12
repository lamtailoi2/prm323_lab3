// Resolves the Firebase service account for both local runs and Vercel.
// Local: INTERNLY_ADMIN_SA / GOOGLE_APPLICATION_CREDENTIALS / the default file.
// Vercel: FIREBASE_SERVICE_ACCOUNT (JSON) or FIREBASE_SERVICE_ACCOUNT_BASE64.

import fs from 'node:fs';

/// Reads a JSON service account from the environment, if present.
/// Returns `{ serviceAccount, source, error }`; parsing errors are reported
/// instead of crashing the serverless function at import time.
export function readEnvServiceAccount(env = process.env) {
  const raw = env.FIREBASE_SERVICE_ACCOUNT;
  if (raw && raw.trim()) {
    try {
      return {
        serviceAccount: JSON.parse(raw),
        source: 'FIREBASE_SERVICE_ACCOUNT',
        error: null,
      };
    } catch (error) {
      return { serviceAccount: null, source: 'FIREBASE_SERVICE_ACCOUNT', error };
    }
  }

  const base64 = env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (base64 && base64.trim()) {
    try {
      return {
        serviceAccount: JSON.parse(
          Buffer.from(base64.trim(), 'base64').toString('utf8'),
        ),
        source: 'FIREBASE_SERVICE_ACCOUNT_BASE64',
        error: null,
      };
    } catch (error) {
      return {
        serviceAccount: null,
        source: 'FIREBASE_SERVICE_ACCOUNT_BASE64',
        error,
      };
    }
  }

  return { serviceAccount: null, source: null, error: null };
}

/// Reads a service-account key from a file. Returns null when the file does
/// not exist or cannot be parsed.
export function readFileServiceAccount(filePath, fsImpl = fs) {
  if (!filePath || !fsImpl.existsSync(filePath)) return null;
  try {
    return JSON.parse(fsImpl.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}
