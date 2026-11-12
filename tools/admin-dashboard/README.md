# Internly admin dashboard

A small ops console for the things we used to do in the Firebase Console:
sending test / real FCM notifications, finding a device token, inspecting or
deleting a student's notification history, and reading GA4 realtime numbers.

It is a **React (Vite) UI + Express API** and runs in two places:

- locally at <http://127.0.0.1:4317> (`npm run dev`), or
- deployed on **Vercel** as a static React app plus one serverless function.

The browser never sees a credential. It signs in with Google, sends the
Firebase ID token, and the server verifies the token and checks the email
against `ADMIN_EMAILS` before touching Firestore, Auth, FCM or GA4.

## Structure

| Path | What it is |
|---|---|
| `src/` | React UI (`App.jsx`, components, styles, Firebase client, API client) |
| `server/app.js` | Express app: auth gate, users, notifications, send, test crash, GA4 |
| `server/local.js` | Local dev server: the same Express app + Vite middleware on 4317 |
| `api/[...path].js` | Vercel catch-all function that exports the Express app |
| `lib/` | Pure, unit-tested helpers (`admin.js`, `analytics.js`, `auth.js`, `credentials.js`) |
| `test/` | `node --test` suites, no Firebase project or credentials needed |

## Access

Every `/api/*` request requires `Authorization: Bearer <Firebase ID token>`.

| Situation | Response |
|---|---|
| No token | `401 Sign in to use the dashboard.` |
| Google account not in `ADMIN_EMAILS` | `403 This Google account is not allowed to use the dashboard.` |
| `ADMIN_EMAILS` missing | `503` with the variable to set |
| No service-account credential | `503` with the credential variable to set |

The server also requires `email_verified = true` (Google accounts always are).

## Local setup

1. Firebase Console → ⚙ **Project settings** → **Service accounts** →
   **Generate new private key**. Save the `.json` **outside the repository**:

   ```powershell
   mkdir "$env:USERPROFILE\.internly-admin"
   move "$env:USERPROFILE\Downloads\<project>-firebase-adminsdk-*.json" "$env:USERPROFILE\.internly-admin\service-account.json"
   ```

2. Create `tools/admin-dashboard/.env.local` from `.env.example` and fill it.
   This project already has the web app **Internly Ops**. Print its config
   with:

   ```powershell
   firebase apps:sdkconfig WEB 1:888219308403:web:0aa12a147b36ae2dc03506 --project prm-lab3
   ```

   For `prm-lab3` the values are:

   ```dotenv
   VITE_FIREBASE_API_KEY=AIzaSyAHd1Qneh3QZj_A1C1jw_MMMF5sCS_-jGU
   VITE_FIREBASE_AUTH_DOMAIN=prm-lab3.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=prm-lab3
   VITE_FIREBASE_APP_ID=1:888219308403:web:0aa12a147b36ae2dc03506
   ADMIN_EMAILS=lap262005@gmail.com
   GA4_PROPERTY_ID=123456789
   ```

   `.env.local` is gitignored. The `VITE_` values are the public Firebase web
   app config, not secrets. `server/local.js` copies the same file into the
   Express process, so `ADMIN_EMAILS`, `GA4_PROPERTY_ID` and credential
   overrides work locally too.

3. Install and start (from `tools/admin-dashboard`):

   ```powershell
   npm install --include=dev
   npm run dev
   ```

   `--include=dev` is needed when the shell has `NODE_ENV=production`, which
   makes npm skip Vite and the React plugin. Vercel installs dev dependencies
   itself.

4. Open <http://127.0.0.1:4317> and sign in with an allowlisted Google account.

## Deploy to Vercel

1. Push the repository, then Vercel → **Add New** → **Project** → import it.
2. Set **Root Directory** to `tools/admin-dashboard`. Vercel detects **Vite**;
   build `npm run build`, output `dist`.
3. Add these environment variables (Production, Preview and Development):

   | Name | Value |
   |---|---|
   | `VITE_FIREBASE_API_KEY` | Firebase web app config |
   | `VITE_FIREBASE_AUTH_DOMAIN` | e.g. `prm-lab3.firebaseapp.com` |
   | `VITE_FIREBASE_PROJECT_ID` | e.g. `prm-lab3` |
   | `VITE_FIREBASE_APP_ID` | Firebase web app id |
   | `ADMIN_EMAILS` | Comma-separated Google emails allowed to sign in |
   | `FIREBASE_SERVICE_ACCOUNT_BASE64` | Base64 of the service-account JSON |
   | `GA4_PROPERTY_ID` | Optional, numeric GA4 property id |
   | `INTERNLY_PROJECT_ID` | Optional, overrides the project id |

   `FIREBASE_SERVICE_ACCOUNT` (raw JSON) also works if the dashboard accepts
   the multiline value. Base64 avoids newline escaping problems in shells.

   For this repository (`prm-lab3`), the four `VITE_` values are the ones in
   the local setup above. `ADMIN_EMAILS` starts as `lap262005@gmail.com`; add
   teammates as needed.

4. Copy the base64 key on PowerShell (one line; ends with the value on your
   clipboard):

   ```powershell
   $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Raw "$env:USERPROFILE\.internly-admin\service-account.json"))); Set-Clipboard -Value $b64
   ```

5. Firebase Console → **Authentication** → **Sign-in method** → enable
   **Google**.
6. Firebase Console → **Authentication** → **Settings** → **Authorised
   domains** → add your Vercel domain, e.g. `internly-ops.vercel.app`.
   `localhost` is already allowed for local development.
7. Deploy, open the Vercel URL, and sign in. The header shows the project,
   credential source and the signed-in admin.

`VITE_*` values are compiled into the bundle: after changing one, redeploy
(not just restart). Server variables (`ADMIN_EMAILS`, the credential,
`GA4_PROPERTY_ID`) take effect on the next function invocation.

## Scripts

```powershell
npm run dev      # local Express + Vite on http://127.0.0.1:4317
npm run build    # production React bundle in dist/
npm test         # node --test (helpers, auth allowlist, GA4 parser)
```

## What it does

- **Users** — `users/{uid}` joined with Firebase Auth: name, email, uid,
  device token and when it was last stored. Copy a token with one click. The
  recipient picker in the compose form uses the same list.
- **Send notification** — choose **one recipient** or **everyone with a
  token**. Students without a device token appear disabled with the reason, so
  a send cannot silently target an unreachable device. Title, optional body,
  optional in-app `route` (`/home`, `/search`, `/saved`, `/applications`,
  `/profile` or a path below one of them, e.g.
  `/home/internships/<jobKey>`). The server reports per-recipient successes
  and FCM error codes. A send covers up to 1000 user documents (duplicate
  tokens are sent once).
- **Notification history** — reads `users/{uid}/notifications` (newest first,
  read / unread, route, time) and deletes one entry or clears the list.
- **Analytics (GA4 realtime)** — active users and top events from the GA4
  property linked to the Firebase project, refreshed every 15 s. See
  [Analytics (GA4 realtime)](#analytics-ga4-realtime).
- **Crash test** — sends a data-only FCM command (`type=test_crash`) to the
  same recipient selection. Every selected app closes immediately and uploads
  a fatal report on its next launch. The action requires the acknowledgment
  checkbox and a confirmation dialog; it writes no notification or history
  document. The on-device control stays at Profile → Diagnostics → *Simulate
  app crash*.

When **Write to the user's notification history** is checked, the server also
writes the document with the FCM message ID as its ID, the same ID the app uses
when it receives the message, so the two writes merge instead of duplicating.
The crash command deliberately skips this write: the app recognises the
control message before its notification handlers and crashes instead.

## Analytics (GA4 realtime)

The card reads the GA4 property linked to the Firebase project. It does not
use the Firebase Admin SDK; the server calls the GA4 Data API
(`runRealtimeReport`).

1. GA4 → **Admin** → **Property settings** → **Property details**: copy the
   numeric **Property ID** (not the `G-...` measurement id). It is also in the
   Firebase Console link to the property.
2. Google Cloud Console (the project that owns the service-account key) →
   **APIs & Services** → **Library** → enable **Google Analytics Data API**.
3. GA4 → **Admin** → **Property access management** → add the key's
   `client_email` as **Viewer**.
4. Set `GA4_PROPERTY_ID` (locally in `.env.local`, on Vercel in the project
   environment variables) and restart/redeploy.
5. Check the endpoint after signing in (the browser sends the token; from the
   terminal, use the token from the app's network tab):

   ```powershell
   curl.exe -H "Authorization: Bearer <id-token>" https://<your-app>.vercel.app/api/analytics/realtime
   ```

   It returns `activeUsers`, `totalEvents`, `rows` (`event`, `events`; `users`
   is `null` there because GA4 does not allow `activeUsers` together with the
   `eventName` dimension), `quotaRemaining` and `fetchedAt`. The server makes
   two small queries (totals and top events), caches for 10 s, and the UI
   refreshes every 15 s.

The GA4 realtime report covers the last **30 minutes** (60 for Analytics 360)
and is aggregated, not a per-event DebugView. The Data API is free within its
quota: a standard property allows 200,000 realtime tokens per day, 40,000 per
hour and 14,000 per project per property per hour, so a 15 s poll is well
inside the free tier.

## Security

- Google sign-in is required; the server verifies the Firebase ID token with
  the Admin SDK on every API call.
- The email must be in `ADMIN_EMAILS`, so a public URL alone is not enough to
  send notifications or crash test devices.
- The service-account key is read from the server environment (or a file
  outside the repository for local runs) and is never sent to the browser.
- No secret is stored in the repository. `.env.local` is gitignored.
- The local server binds `127.0.0.1`. The deployed function is public but
  protected by the token + allowlist checks above.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Login button says Firebase is not configured | `VITE_FIREBASE_*` variables are missing from the build; set them and redeploy. |
| `auth/unauthorized-domain` | Add the exact host you opened (`localhost` and `127.0.0.1` are different) or the Vercel domain in Firebase Authentication → Settings → Authorised domains. |
| API returns `401 Sign in to use the dashboard.` | The session expired; sign out and sign in again. |
| API returns `403 This Google account is not allowed…` | Add the email to `ADMIN_EMAILS` and redeploy/reinvoke. |
| `ADMIN_EMAILS is not set` | Set the comma-separated allowlist in the environment. |
| Header says **No credential** | Set `FIREBASE_SERVICE_ACCOUNT_BASE64` (or `FIREBASE_SERVICE_ACCOUNT`), or locally save the key to `%USERPROFILE%\.internly-admin\service-account.json`. |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` parse error | Re-copy the JSON and base64-encode it again; the value must be one line. |
| `permission/insufficient-permissions` | The key belongs to another project, or the service account was restricted in IAM. Generate a fresh key for `prm-lab3`. |
| User shows **No token** | Open the app on that device while signed in; the coordinator stores the token after sign-in. |
| Send reports `messaging/registration-token-not-registered` | The app was uninstalled or the token rotated; open the app again so it stores the new token. |
| Send fails with `messaging/invalid-argument` | Check the custom data: `route` must be an in-app path (the form validates it). |
| Crash command succeeds but the app does not close | Install the current app build (the `type=test_crash` handler is in `NotificationService`) and make sure the chosen user has a device token. Data messages need Google Play services. |
| Analytics says `GA4_PROPERTY_ID is not set` | Set the numeric property id in the environment and redeploy. |
| Analytics returns `403 PERMISSION_DENIED` | The service account is not a Viewer on the property, or the Data API is disabled. Add `client_email` in GA4 Property access management and enable the API. |
| Analytics returns `404` | Wrong property id. Use the numeric GA4 property id, not the `G-...` measurement id. |
| Analytics returns `429` | Realtime quota exhausted. Wait for the reset or poll less often; the dashboard already caches for 10 s. |
