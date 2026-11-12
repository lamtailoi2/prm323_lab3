import { useState } from 'react';

import { firebaseReady, signInWithGoogle } from '../firebase';

const AUTH_MESSAGES = {
  'auth/popup-closed-by-user': 'Sign-in was cancelled.',
  'auth/popup-blocked':
    'The browser blocked the sign-in popup. Allow popups and try again.',
  'auth/unauthorized-domain':
    'This domain is not authorised in Firebase Authentication → Settings → Authorised domains.',
  'auth/operation-not-allowed':
    'Enable Google sign-in in Firebase Authentication → Sign-in method.',
};

export default function LoginScreen() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function handleSignIn() {
    setBusy(true);
    setError(null);
    try {
      await signInWithGoogle();
    } catch (cause) {
      setError(AUTH_MESSAGES[cause.code] || cause.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="login">
      <section className="login-card" aria-labelledby="login-title">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            I.
          </span>
          <div className="brand-copy">
            <p className="eyebrow">Operations desk</p>
            <h1>Internly Ops</h1>
          </div>
        </div>

        <p className="body-copy">
          This dashboard sends real push notifications and crash commands. Sign
          in with a Google account listed in <code>ADMIN_EMAILS</code>.
        </p>

        {!firebaseReady ? (
          <div className="result bad" role="alert">
            Firebase is not configured in this build. Set{' '}
            <code>VITE_FIREBASE_API_KEY</code>,{' '}
            <code>VITE_FIREBASE_AUTH_DOMAIN</code>,{' '}
            <code>VITE_FIREBASE_PROJECT_ID</code> and{' '}
            <code>VITE_FIREBASE_APP_ID</code>, then rebuild.
          </div>
        ) : null}

        <div className="form-actions">
          <button
            className="button primary"
            type="button"
            onClick={handleSignIn}
            disabled={busy || !firebaseReady}
            aria-busy={busy}
          >
            {busy ? 'Signing in…' : 'Continue with Google'}
          </button>
        </div>

        {error ? (
          <div className="result bad" role="alert">
            {error}
          </div>
        ) : null}
      </section>
    </main>
  );
}
