import { auth } from './firebase';

/// Calls the admin API with the signed-in user's ID token. Errors keep the
/// server's `hint` so the banner can explain the fix.
export async function api(path, options = {}) {
  const token = auth?.currentUser
    ? await auth.currentUser.getIdToken()
    : null;

  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers ?? {}),
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const response = await fetch(path, { ...options, headers });
  let payload = {};
  try {
    payload = await response.json();
  } catch {
    // A non-JSON error (proxy, server crash) still gets a readable message.
  }
  if (!response.ok) {
    const error = new Error(
      payload.error || `Request failed (${response.status}).`,
    );
    error.hint = payload.hint;
    error.status = response.status;
    throw error;
  }
  return payload;
}
